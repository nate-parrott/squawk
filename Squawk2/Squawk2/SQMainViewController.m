//
//  SQMainViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQMainViewController.h"
#import "SQAPI.h"
#import "NPAddressBook.h"
#import <AVFoundation/AVFoundation.h>
#import "SQThreadCell.h"
#import "SQFriendsOnSquawk.h"
#import "WSEarSensor.h"
#import "WSContactBoost.h"
#import "SQSquawkCache.h"
#import "SQNewThreadViewController.h"
#import "SQTheme.h"
#import <QuartzCore/QuartzCore.h>
#import <Helpshift/Helpshift.h>
#import "SQBackgroundTaskManager.h"
#import "UIViewController+SoftModal.h"
#import "SQOnboardingViewController.h"

NSString * const SQHasUsedRaiseToSquawk = @"SQHasUsedRaiseToSquawk";

//#define TOP_BAR_SCROLLS

#define PULL_TO_REFRESH_THRESHOLD 70

const CGPoint SQDefaultContentOffset = {0, 0};

@interface SQMainViewController () <MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate, ABNewPersonViewControllerDelegate> {
    IBOutlet UIView* _searchFieldContainer;
    IBOutlet UITextField* _searchField;
    
    IBOutlet UILabel* _titleLabel;
    
    CADisplayLink* _statusDisplayUpdater;
    
    NSTimer* _updater;
    
    NSTimeInterval _tapStartTime;
    
    IBOutlet UIView* _squawkListPadding;
        
    BOOL _didRefreshDuringPull;
    
    UIButton* _pushNotificationAdvert;
    
    IBOutlet UILabel* _pullToRefreshLabel;
    
    MFMessageComposeViewController* _messageComposer;
}

@property(nonatomic)BOOL searchMode;
@property(strong)NSString* searchQuery;
@property(nonatomic)BOOL inviteFriendsPromptVisible;

@end

@implementation SQMainViewController

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SQThemeChangedNotification object:nil] startWith:nil] subscribeNext:^(id x) {
        self.view.backgroundColor = [SQTheme mainBackground];
        _raiseToSquawkHintContainer.backgroundColor = [[SQTheme mainUITint] colorWithAlphaComponent:0.75];
    }];
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:SQThemeChangedNotification object:nil] subscribeNext:^(id x) {
        [self.tableView reloadData];
    }];
    
    _tableView.hidden = YES;
    
    for (UIView* view in _headerView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* b = (UIButton*)view;
            [b setImage:[b.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
    
    // apply CALayer perspective:
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = 1.0 / -2000;
    self.view.layer.sublayerTransform = perspective;
    
    _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
    
    self.view.tintColor = [UIColor whiteColor];
    
    _searchField.placeholder = NSLocalizedString(@"Search", @"Search bar placeholder");
    
    self.inviteFriendsPromptVisible = NO;
    
    self.audioActionQueue = [NSMutableArray new];
    
    _pushNotificationAdvert = [UIButton buttonWithType:UIButtonTypeCustom];
    [_pushNotificationAdvert setTitle:NSLocalizedString(@"Tap to enable push notifications", @"") forState:UIControlStateNormal];
    [_pushNotificationAdvert setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pushNotificationAdvert.titleLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:13]];
    RAC(_pushNotificationAdvert, hidden) = RACObserve(AppDelegate, pushNotificationsEnabled);
    [_pushNotificationAdvert addTarget:self action:@selector(enablePush:) forControlEvents:UIControlEventTouchUpInside];
#ifdef PRETTIFY
    _pushNotificationAdvert.alpha = 0;
#endif
    
    RAC(_titleLabel, text) = [RACObserve(AppDelegate, globalProperties) map:^id(NSDictionary* props) {
        if (props[@"title"] && [[NSLocale preferredLanguages].firstObject isEqualToString:@"en"]) {
            return props[@"title"];
        }
        return NSLocalizedString(@"this is Squawk", @"Default main screen title");
    }];
    
    _errorContainer.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"strips"]];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:SQDidOpenMessageNotification object:nil] subscribeNext:^(id x) {
        [self.tableView setContentOffset:CGPointZero];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didOpenMessage:) name:SQDidOpenMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(promptAddFriend:) name:SQPromptAddFriend object:nil];
    
    [self setupDataBindings];
    
    [self setupFocusBindings];
    
    [self setupErrorMessaging];
    
    [self setupStatusDisplay];
    
    [self setupAlertView];
    
    self.searchMode = NO;
    
    [RACObserve(self, selectedThread) subscribeNext:^(id x) {
        if (x==nil && self.tableView.indexPathsForSelectedRows.count) {
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathsForSelectedRows.firstObject animated:YES];
        };
    }];
    
    RAC(self, searchQuery) = [[RACSignal combineLatest:@[RACObserve(self, searchMode), _searchField.rac_textSignal] reduce:^id(NSNumber* inSearchMode, NSString* searchQuery){
        return inSearchMode.boolValue? searchQuery : nil;
    }] throttle:0.1];
    
    RAC(_bird, animating) = RACObserve(self, loading);
    
    [RACObserve(self, currentAudioAction) subscribeNext:^(id x) {
        if ([self.currentAudioAction isKindOfClass:[SQAudioPlayerAction class]] && self.interactingWithThread) {
            NSString* threadID = self.interactingWithThread.identifier;
            [[NSUserDefaults standardUserDefaults] setObject:threadID forKey:SQCheckmarkVisibleNextToThreadIdentifier];
        }
    }];
    
    
    
/*#ifdef TAKING_DEFAULT_IMAGE
    for (UIView* v in @[_searchField, _titleLabel]) {
        [v removeFromSuperview];
    }
    self.view.tintColor = [UIColor colorWithWhite:0.910 alpha:1.000];
    _squawkBarBackgroundLayer.backgroundColor = self.view.tintColor.CGColor;
#endif*/
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController* root = [segue.destinationViewController viewControllers].firstObject;
        if ([root isKindOfClass:[SQThreadMakerViewController class]]) {
            SQThreadMakerViewController* vc = (id)root;
            RAC(vc, threads) = RACObserve(self, allThreads);
        }
    }
}*/
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self scrollViewDidScroll:self.tableView];
    
    self.lateEnoughToShowError = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.lateEnoughToShowError = YES;
    });
    
    if ([SQAPI currentPhone]!=nil && self.presentedViewController==nil) {
        [self requestPermissions];
    }
}
-(void)viewDidAppear:(BOOL)animated {
    if (!_setupLoginHooks) {
        _setupLoginHooks = YES;
        [[[SQAPI loginStatus] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
            if ([x boolValue]==NO && self.presentedViewController==nil) {
                UIViewController* onboarding = [[UIStoryboard storyboardWithName:@"Onboarding" bundle:nil] instantiateInitialViewController];
                onboarding.transitioningDelegate = self;
                [self presentViewController:onboarding animated:YES completion:nil];
            }
        }];
    }
}
-(IBAction)newThread:(id)sender {
    SQNewThreadViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NewThread"];
    vc.squawkers = self.allThreads;
    [vc presentSoftModalInViewController:self];
}
#pragma mark Notification callbacks
-(void)didOpenMessage:(NSNotification*)notif {
    self.tableView.contentOffset = CGPointZero;
}
-(void)promptAddFriend:(NSNotification*)notif {
    [self newThread:nil];
}
#pragma mark Layout
-(BOOL)automaticallyAdjustsScrollViewInsets {
    return NO;
}
-(void)setInviteFriendsPromptVisible:(BOOL)inviteFriendsPromptVisible {
    _inviteFriendsPromptVisible = inviteFriendsPromptVisible;
    _inviteFriendsPrompt.hidden = !_inviteFriendsPromptVisible;
}
#pragma mark Permissions
-(void)requestPermissions {
    [NPAddressBook startPopulatingContactsSignal];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        AppDelegate.hasRecordPermission = granted;
    }];
    [AppDelegate setupPushNotifications];
}
#pragma mark Data
-(void)setupDataBindings {
    _tableViewReloaded = [RACSubject subject];
    
    RACSignal* latestSquawks = [RACObserve([SQSquawkCache shared], squawks) distinctUntilChanged];
    
    RACSignal* contactsList = [NPAddressBook contacts];
    RACSignal* friendsOnSquawk = [[SQFriendsOnSquawk shared] setOfPhoneNumbersOfFriendsOnSquawk];
    
    [contactsList subscribeNext:^(id x) {
        self.contactsAuthorization = x!=nil;
    }];
    
    RACSignal* boostsUpdated = [WSContactBoost updateSignal];
    
    RAC(self, allThreads) = [[[[[RACSignal combineLatest:@[contactsList, latestSquawks, friendsOnSquawk, boostsUpdated]] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] reduceEach:^id(NSArray* contacts, NSArray* squawks, NSSet* friendsOnSquawk, id boosts){
        if (contacts == nil) return nil;
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        [AppDelegate logInstrumentsEvent:"Starting thread generation"];
        NSArray* threads = [SQThread makeThreadsFromRecentSquawks:squawks contacts:contacts];
        NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate] - t;
        [AppDelegate logInstrumentsEvent:"Done with thread generation"];
        NSLog(@"ELAPSED: %f", time);
        return threads;
    }] publish] autoconnect];
    
    RACSignal* filteredThreadSections = [[[[RACSignal combineLatest:@[RACObserve(self, allThreads), RACObserve(self, searchQuery)]] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] map:^id(RACTuple* value) {
        NSArray* threads = value.first;
        NSString* query = value.second;
        NSArray* filtered = [SQThread searchThreads:threads withQuery:query];
        return [SQThread sortThreadsIntoSections:filtered];
    }] deliverOn:[RACScheduler mainThreadScheduler]];
    
    [[RACSignal combineLatest:@[filteredThreadSections, RACObserve(self, currentAudioAction)]] subscribeNext:^(RACTuple* x) {
        NSArray* sections = x.first;
        SQAudioAction* currentAudioAction = x.second;
        if (currentAudioAction==nil && sections!=self.threadSections) {
            self.threadSections = sections;
            // update the selected thread:
            self.selectedThread = [[[self.threadSections.rac_sequence flattenMap:^RACStream *(id value) {
                return [value rac_sequence];
            }] filter:^BOOL(id value) {
                return [[value identifier] isEqualToString:self.selectedThread.identifier];
            }] take:1].array.firstObject;
            [self.tableView reloadData];
            if (self.tableView.hidden && self.threadSections.count) {
                [AppDelegate logInstrumentsEvent:"Loaded main content"];
                [self startInitialRowRevealAnimation];
            }
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                [[SQBackgroundTaskManager shared] completedBackgroundTaskCallback];
            }
        }
    }];
    
    [RACObserve(self, threadSections) subscribeNext:^(id x) {
        [self.tableView reloadData];
        [_tableViewReloaded sendNext:nil];
    }];
    
    RAC(self, loading) = [RACObserve([SQSquawkCache shared], fetchInProgress) deliverOn:[RACScheduler mainThreadScheduler]];
    
    // setup pull to refresh callback:
    [RACObserve(self, loading) subscribeNext:^(id x) {
        if ([x boolValue]) {
            if ([_pullToRefreshLabel.text isEqualToString:NSLocalizedString(@"Refreshing", @"").lowercaseString]) {
                _pullToRefreshLabel.text = NSLocalizedString(@"Refreshed", @"").lowercaseString;
            }
        }
    }];
    
    [[[RACSignal combineLatest:@[latestSquawks, friendsOnSquawk]] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(RACTuple* results) {
        NSArray* squawks = results.first;
        NSSet* phones = results.second;
        self.inviteFriendsPromptVisible = phones!=nil && phones.count==0 && squawks.count==0;
    }];
    
    [_tableViewReloaded subscribeNext:^(id x) {
        NSString* mostRecentSquawkID = [[[self.threadSections.firstObject firstObject] squawks].firstObject objectForKey:@"_id"];
        if (![mostRecentSquawkID isEqualToString:_mostRecentSquawkID]) {
            [self.tableView setContentOffset:SQDefaultContentOffset animated:!!_mostRecentSquawkID];
            self.selectedThread = [self.threadSections.firstObject firstObject];
            _mostRecentSquawkID = mostRecentSquawkID;
        }
    }];
    
    if (YES) { // logging
        [[[contactsList filter:^BOOL(id value) {
            return [value count]>0;
        }] take:1] subscribeNext:^(id x) {
            [AppDelegate logInstrumentsEvent:"Contacts loaded"];
        }];
        
        [[[RACObserve([SQSquawkCache shared], squawks) filter:^BOOL(id value) {
            return [value count]>0;
        }] take:1] subscribeNext:^(id x) {
            [AppDelegate logInstrumentsEvent:"Contacts loaded"];
        }];
        
        [[boostsUpdated take:1] subscribeNext:^(id x) {
            [AppDelegate logInstrumentsEvent:"Boosts loaded"];
        }];
        
        [[friendsOnSquawk take:1] subscribeNext:^(id x) {
            [AppDelegate logInstrumentsEvent:"Friends on squawk loaded"];
        }];
        
        [[[RACObserve(self, allThreads) filter:^BOOL(id value) {
            return !!value;
        }] take:1] subscribeNext:^(id x) {
            [AppDelegate logInstrumentsEvent:"All threads"];
        }];
    }
}
-(void)setupErrorMessaging {
    //RACSignal* pushStatus = RACObserve(AppDelegate, registeredForPushNotifications);
    RACSignal* microphoneAuth = RACObserve(AppDelegate, hasRecordPermission);
    RACSignal* fetchError = RACObserve([SQSquawkCache shared], error);
    RACSignal* contactsStatus = RACObserve(self, contactsAuthorization);
    RACSignal* volume = RACObserve(((AVAudioSession*)[AVAudioSession sharedInstance]), outputVolume);
    RACSignal* lateEnough = RACObserve(self, lateEnoughToShowError);
    RAC(_errorLabel, text) = [[[RACSignal combineLatest:@[microphoneAuth, fetchError, contactsStatus, volume, lateEnough]] map:^id(id value) {
        //if (!self.lateEnoughToShowError) return @"";
        
        NSMutableArray* messages = [NSMutableArray new];
/*#ifndef TARGET_IPHONE_SIMULATOR
        if (![AppDelegate registeredForPushNotifications]) {
            [messages addObject:NSLocalizedString(@"Push notifications are off. To receive Squawks, turn them on in Settings, under Notifications.", @"")];
        }
#endif*/
        if ([SQSquawkCache shared].error) {
            [messages addObject:NSLocalizedString(@"Couldn't connect to the Internet.", @"")];
        }
        if (self.contactsAuthorization==NO) {
            [messages addObject:NSLocalizedString(@"Give Squawk access to your contacts, in the Settings app, under Privacy.", @"")];
        }
        if ([[AVAudioSession sharedInstance] outputVolume]==0) {
            [messages addObject:NSLocalizedString(@"Your volume is zero. You won't be able to hear Squawks.", @"")];
        }
        if (AppDelegate.hasRecordPermission==NO) {
            [messages addObject:NSLocalizedString(@"Squawk doesn't have access to your microphone. Give Squawk access in Settings, under Privacy.", @"")];
        }
        return messages.count? [messages componentsJoinedByString:@"\n"] : nil;
    }] deliverOn:[RACScheduler mainThreadScheduler]];
    RAC(_errorContainer, hidden) = [RACObserve(_errorLabel, text) map:^id(id value) {
#ifdef TAKING_DEFAULT_IMAGE
        return @YES;
#endif
        return @([value length]==0);
    }];
}
#pragma mark Tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#ifdef TAKING_DEFAULT_IMAGE
    return 0;
#endif
    return _threadSections.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_threadSections[section] count];
}
-(SQThread*)threadForIndexPath:(NSIndexPath*)path {
    return self.threadSections[path.section][path.row];
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SQThreadCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Thread" forIndexPath:indexPath];
    
    int totalIndex = indexPath.row;
    for (int i=0; i<indexPath.section; i++) {
        totalIndex += [_threadSections[i] count];
    }
    cell.brightness = (cosf(totalIndex/2.0)+1)/2;
    cell.saturation = 1;// - indexPath.section/3.0;
    cell.thread = [self threadForIndexPath:indexPath];
    cell.sqSelected = [self.selectedThread isEqual:cell.thread];
    cell.controller = self;
    
    return cell;
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat landingY = 0;
    
    CGFloat rowHeight = [self tableView:self.tableView heightForRowAtIndexPath:nil];
    CGFloat headerHeight = [self tableView:self.tableView heightForHeaderInSection:1];
    
    CGFloat y = 0;
    int section = 0;
    int index = 0;
    while (section < _threadSections.count) {
        if (index >= [_threadSections[section] count]) {
            section++;
            index = 0;
            y += headerHeight;
        } else {
            if (fabsf(y-targetContentOffset->y) < fabsf(landingY-targetContentOffset->y)) {
                landingY = y;
            }
            
            index++;
            y += rowHeight;
        }
    }
    
    targetContentOffset->y = landingY;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedThread = _threadSections[indexPath.section][indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_searchField resignFirstResponder];
    
    _didRefreshDuringPull = NO;
    
    self.selectedThread = nil;
    
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[SQThreadCell class]]) {
            [(SQThreadCell*)cell scrolled];
        }
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _pullToRefreshLabel.alpha = MIN(1, MAX(0, -scrollView.contentOffset.y/PULL_TO_REFRESH_THRESHOLD));
    _headerView.alpha = MIN(1, MAX(0, 1-scrollView.contentOffset.y/60));
    
    if (!_didRefreshDuringPull) {
        CGFloat pullProgress = -scrollView.contentOffset.y / PULL_TO_REFRESH_THRESHOLD;
        pullProgress = MIN(1, MAX(0, pullProgress));
        if (pullProgress == 1) {
            _didRefreshDuringPull = YES;
            [[SQSquawkCache shared] fetch];
            _pullToRefreshLabel.text = NSLocalizedString(@"Refreshing", @"").lowercaseString;
        }
    }
    
#ifdef TOP_BAR_SCROLLS
    _headerTopOffset.constant = MIN(0, -scrollView.contentOffset.y);
#endif
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 30;
    if (section==1) return height;
    if (section==0 || section >= self.threadSections.count || [self.threadSections[section] count]==0) {
        return 0;
    }
    return height;
}
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    if (section==1) {
        [v addSubview:_pushNotificationAdvert];
        _pushNotificationAdvert.frame = CGRectMake(0, 0, v.frame.size.width, v.frame.size.height);
        _pushNotificationAdvert.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    
    return v;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
#pragma mark Focus/squawking
-(void)setupFocusBindings {
    [RACObserve(self, selectedThread) subscribeNext:^(id x) {
        for (SQThreadCell* cell in self.tableView.visibleCells) {
            cell.sqSelected = x && [cell.thread isEqual:x];
        }
    }];
    
    RAC(self, interactingWithThread) = [RACSignal combineLatest:@[RACObserve(self, selectedThread), RACObserve(self, pressedThread)] reduce:^id(SQThread* selected, SQThread* pressed){
        if (pressed) return pressed;
        return selected;
    }];
    
    RACSignal* squawkUpdateSignal = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:SQThreadUpdatedNotification object:nil] startWith:nil];
    [[RACSignal combineLatest:@[RACObserve(self, selectedThread), squawkUpdateSignal, [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:SQCheckmarkVisibleNextToThreadIdentifier observer:nil]]] subscribeNext:^(id x) {
        
        if (_selectedThread) {
            [self updateRaiseToSquawkHintWithThread:_selectedThread];
        }
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            BOOL showHint = self.selectedThread!=nil && ![[NSUserDefaults standardUserDefaults] boolForKey:SQHasUsedRaiseToSquawk];
            _raiseToSquawkHintContainer.alpha = showHint? 1 : 0;
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil] subscribeNext:^(id x) {
        [self clearAudioActionQueue];
    }];
    
    RAC(self, playOrRecord) = [[RACSignal combineLatest:@[RACObserve(self, tapDown), RACObserve([WSEarSensor shared], isRaisedToEar), RACObserve(self, pressedThread)] reduce:^id(NSNumber* tapDown, NSNumber* raisedToEar, SQThread* pressedThread){
        return @((tapDown.boolValue || raisedToEar.boolValue || !!pressedThread) && self.presentedViewController==nil);
    }] deliverOn:[RACScheduler mainThreadScheduler]];
}
-(void)updateRaiseToSquawkHintWithThread:(SQThread*)thread {
    BOOL playback = thread.unread.count>0;
    BOOL raiseToSquawkAvailable = [WSEarSensor shared].isAvailable;
#ifdef PRETTIFY
    raiseToSquawkAvailable = YES;
#endif
    NSDictionary* mainAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Demibold" size:13], NSForegroundColorAttributeName: [UIColor blackColor]};
    NSDictionary* subtitleAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:11], NSForegroundColorAttributeName: [UIColor blackColor]};
    
    NSString* firstName = thread.veryShortName;
    
    NSMutableAttributedString* playbackTitle = [NSMutableAttributedString new];
    NSMutableAttributedString* recordTitle = [NSMutableAttributedString new];
    if (raiseToSquawkAvailable) {
        [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Raise to ear to listen to %@", @""), firstName] attributes:mainAttributes]];
        [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nor tap and hold their name", @"") attributes:subtitleAttributes]];
        
        [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Raise to ear to squawk %@", @""), firstName] attributes:mainAttributes]];
        [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nor tap and hold their name", @"") attributes:subtitleAttributes]];
    } else {
        [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Listen to %@ by tapping and holding their name", @""), firstName] attributes:mainAttributes]];
        
        [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Squawk %@ by tapping and holding their name", @""), firstName] attributes:mainAttributes]];
    }
    _raiseToSquawkHint.attributedText = playback? playbackTitle : recordTitle;
}
-(void)setPlayOrRecord:(BOOL)playOrRecord {
    if (_playOrRecord == playOrRecord) return;
    _playOrRecord = playOrRecord;
    
    if (playOrRecord) {
        if (self.interactingWithThread) {
            UIView* viewForStatusViewPosition = [[self cellForThread:self.interactingWithThread] background];
            _statusView.tintColor = viewForStatusViewPosition.backgroundColor;
            _statusView.frame = [_statusView.superview convertRect:viewForStatusViewPosition.bounds fromView:viewForStatusViewPosition];
            _statusView.touchPoint = [_statusView convertPoint:_touchPoint fromView:self.view];
            
            if ([WSEarSensor shared].isRaisedToEar) {
                self.interactionMode = SQRaisedToEar;
            } else if (self.pressedThread) {
                self.interactionMode = SQPressedRow;
            } else {
                self.interactionMode = SQPressedButton;
            }
            
            // set a boolean after the first time raise-to-squawk is used
            if ([WSEarSensor shared].isRaisedToEar && ![[NSUserDefaults standardUserDefaults] boolForKey:SQHasUsedRaiseToSquawk]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([WSEarSensor shared].isRaisedToEar) {
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SQHasUsedRaiseToSquawk];
                    }
                });
            }
            
            // log stuff:
            BOOL playback = self.interactingWithThread.unread.count;
            NSString* method;
            if ([WSEarSensor shared].isRaisedToEar) {
                method = @"raise_to_squawk";
            } else if (self.pressedThread) {
                method = @"pressed_row_to_squawk";
            } else {
                method = @"pressed_bottom_button";
            }
            [AppDelegate trackEventWithCategory:@"action" action:(playback? @"playback_squawk" : @"record_squawk") label:method value:nil];
            
            // generate queue:
            if (playback) {
                SQAudioAction* startPlaybackPrompt = [SQBlockAction startPlaybackPrompt];
                startPlaybackPrompt.delegate = self;
                [self.audioActionQueue addObject:startPlaybackPrompt];
                for (NSMutableDictionary* squawk in self.interactingWithThread.unread.reverseObjectEnumerator) {
                    SQAudioPlayerAction* action = [SQAudioPlayerAction new];
                    action.delegate = self;
                    action.squawk = squawk;
                    [self.audioActionQueue addObject:action];
                }
                SQAudioAction* doneWithPlaybackPrompt = [SQBlockAction donePlayingPrompt];
                doneWithPlaybackPrompt.delegate = self;
                [self.audioActionQueue addObject:doneWithPlaybackPrompt];
            } else {
                SQAudioAction* startRecordingPrompt = [SQBlockAction startRecordingPrompt];
                startRecordingPrompt.delegate = self;
                [self.audioActionQueue addObject:startRecordingPrompt];
                
                SQAudioRecordingAction* recording = [SQAudioRecordingAction new];
                recording.delegate = self;
                NSMutableArray* phones = [self.interactingWithThread phoneNumbers].allObjects.mutableCopy;
                [phones removeObject:[SQAPI currentPhone]];
                recording.recipients = phones;
                [self.audioActionQueue addObject:recording];
            }
            self.currentAudioAction = self.audioActionQueue.firstObject;
            [self.currentAudioAction start];
        }
    } else {
        //self.interactionMode = SQNoInteraction;
        [self clearAudioActionQueue];
    }
}
#pragma mark Header/search
-(void)setSearchMode:(BOOL)searchMode {
    if (searchMode != _searchMode) {
        [self.tableView setContentOffset:CGPointZero];
    }
    _searchMode = searchMode;
    
    if (searchMode) _searchFieldContainer.hidden = NO;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:(searchMode? 0.5 : 1) initialSpringVelocity:0 options:0 animations:^{
        _searchBarTopOffset.constant = searchMode? 0 : -74;
        [self.view layoutIfNeeded];
        _titleLabel.alpha = searchMode? 0 : 1;
    } completion:^(BOOL finished) {
        if (!searchMode) {
            _searchFieldContainer.hidden = YES;
        }
    }];
    _searchField.text = @"";
    self.searchQuery = @"";
    if (searchMode) {
        [_searchField becomeFirstResponder];
    } else {
        [_searchField resignFirstResponder];
    }
}
-(IBAction)enterSearchMode:(id)sender {
    self.searchMode = YES;
}
-(IBAction)exitSearchMode:(id)sender {
    self.searchMode = NO;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
#pragma mark Feedback
-(IBAction)giveFeedback:(id)sender {
    [[Helpshift sharedInstance] showConversation:self withOptions:nil];
}
#pragma mark Status display
-(SQThreadCell*)cellForThread:(SQThread*)thread {
    for (SQThreadCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[SQThreadCell class]] && [cell.thread isEqual:thread]) {
            return cell;
        }
    }
    return nil;
}
-(void)setupStatusDisplay {
    _statusView = [SQStatusView new];
    _statusView.userInteractionEnabled = NO;
    [self.view addSubview:_statusView];
    
    [[RACObserve(self, currentAudioAction) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        if (x && !_statusDisplayUpdater) {
            _statusDisplayUpdater = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateStatusDisplay)];
            [_statusDisplayUpdater addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else if (x==nil && _statusDisplayUpdater) {
            [_statusDisplayUpdater invalidate];
            _statusDisplayUpdater = nil;
        }
        
        SQStatusViewCard* newStatusView = [self nextStatusView];
        [_statusView replaceStatusViewForIdentifier:@"currentAudioAction" withStatusView:newStatusView];
    }];
    
    [RACObserve(_statusView, visible) subscribeNext:^(id x) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            for (SQThreadCell* cell in self.tableView.visibleCells) {
                cell.interacting = _statusView.visible && CGRectIntersectsRect(cell.bounds, [cell convertRect:_statusView.bounds fromView:_statusView]);
            }
        } completion:^(BOOL finished) {
            
        }];
    }];
}
-(void)updateStatusDisplay {
    [self.currentAudioAction refreshDisplay];
}
-(SQStatusViewCard*)nextStatusView {
    for (SQAudioAction* action in self.audioActionQueue) {
        if (action.statusView) {
            return action.statusView;
        }
    }
    return nil;
}
-(void)setupAlertView {
    self.alertView = [SQFullscreenAlert new];
    [self.view addSubview:self.alertView];
    self.alertView.frame = self.view.bounds;
    self.alertView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.alertView.blackoutColor = [UIColor colorWithWhite:0 alpha:0.9];
    self.alertView.contentColor = [[SQTheme orange] colorWithAlphaComponent:0.3];
    self.alertView.font = [UIFont fontWithName:@"AvenirNext-Medium" size:40];
    self.alertView.contentSize = CGSizeMake(200, 170);
    
    /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.alertView setImage:[UIImage imageNamed:@"ok"] text:@"SENT."];
        [self.alertView presentAndDismissAfter:2.0];
    });*/
}
#pragma mark Audio actions
-(void)audioActionFinished:(SQAudioAction *)action {
    if (action == self.audioActionQueue.firstObject) {
        [self.audioActionQueue removeObjectAtIndex:0];
        self.currentAudioAction = self.audioActionQueue.firstObject;
        if (self.currentAudioAction) {
            DBLog(@"Started %@", [self.currentAudioAction description]);
            [self.currentAudioAction start];
        }
    }
}
-(void)clearAudioActionQueue {
    [self.currentAudioAction stop];
    for (SQAudioAction* action in self.audioActionQueue) {
        if (action.started && !(action.stopped || action.cancelled)) [action abort];
    }
    [self.audioActionQueue removeAllObjects];
    self.currentAudioAction = nil;
}
-(void)audioAction:(SQAudioAction *)action failedWithError:(NSError *)error {
    SQStatusViewCard* status = [[SQStatusViewCard alloc] initWithText:NSLocalizedString(@"Error!", @"") image:[UIImage imageNamed:@"recording-thin"]];
    [_statusView flashStatusView:status duration:2.5];
    [self clearAudioActionQueue];
}
-(void)audioActionDidAbortForTooShortRecording:(SQAudioRecordingAction *)action {
    
}
-(void)audioActionDidRecordSquawk:(SQAudioRecordingAction *)action {
    if (self.interactionMode == SQRaisedToEar) {
        [self.alertView setImage:[UIImage imageNamed:@"ok"] text:NSLocalizedString(@"Sent.", @"").lowercaseString];
        [self.alertView presentQuick:YES andDismissAfter:1.25];
    } else {
        SQStatusViewCard* status = [[SQStatusViewCard alloc] initWithText:NSLocalizedString(@"Sent.", @"") image:[UIImage imageNamed:@"ok-thin"]];
        status.circleSpeed = WSConcentricCirclesViewAdvancedHD2014Hidden;
        [_statusView flashStatusView:status duration:1.5];
        
        [[SQSquawkCache shared] performSelector:@selector(pollIfNeeded) withObject:nil afterDelay:1.0];
    }
}
#pragma mark Misc.
-(void)enablePush:(id)sender {
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PushEnableDialog"];
    [vc presentSoftModalInViewController:self];
}
-(void)rippleFromCell:(UITableViewCell*)center {
    for (SQThreadCell* cell in self.tableView.visibleCells) {
        CGFloat dist = [center convertPoint:CGPointMake(0, cell.bounds.size.height/2) fromView:cell].y / (self.view.bounds.size.height);
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration = 0.15;
        animation.beginTime = CACurrentMediaTime() + fabsf(dist) * 0.4;
        animation.autoreverses = YES;
        animation.repeatCount = 1;
        animation.fromValue = @1;
        animation.toValue = @0.8;
        [[cell background].layer addAnimation:animation forKey:@"Ripple"];
    }
}
-(void)startInitialRowRevealAnimation {
    _tableView.transform = CGAffineTransformMakeTranslation(0, _tableView.frame.size.height);
    _tableView.hidden = NO;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        _tableView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}
#pragma mark Transition animations
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:[SQOnboardingViewController class]]) {
        return (id)presented;
    }
    return nil;
}
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if ([dismissed isKindOfClass:[SQOnboardingViewController class]]) {
        return (id)dismissed;
    }
    return nil;
}
#pragma mark Messaging
-(void)sendMessageToPhones:(NSArray*)phones {
    _messageComposer = [[MFMessageComposeViewController alloc] init];
    _messageComposer.messageComposeDelegate = self;
    _messageComposer.recipients = phones;
    [self presentViewController:_messageComposer animated:YES completion:nil];
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    _messageComposer = nil;
}
#pragma mark Contact creation
-(void)promptToAddContactWithPhone:(NSString*)phone {
    ABRecordRef person = ABPersonCreate();
    
    ABMutableMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(phones, (__bridge CFTypeRef)(phone), kABPersonPhoneMainLabel, NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, phones, NULL);
    
    ABNewPersonViewController* newPersonVC = [[ABNewPersonViewController alloc] init];
    newPersonVC.displayedPerson = person;
    
    [self presentNewPersonVC:newPersonVC];
}
-(void)presentNewPersonVC:(ABNewPersonViewController*)newPersonVC {
    newPersonVC.newPersonViewDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:newPersonVC] animated:YES completion:nil];
}
-(void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    [newPersonView.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
