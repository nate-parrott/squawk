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
#import "SQShimmerView.h"
#import <Helpshift/Helpshift.h>
#import "SQBackgroundTaskManager.h"
#import "UIViewController+SoftModal.h"
#import "SQOnboardingViewController.h"

//#define TOP_BAR_SCROLLS

#define PULL_TO_REFRESH_THRESHOLD 70

const CGPoint SQDefaultContentOffset = {0, 0};

@interface SQMainViewController () {
    IBOutlet UINavigationBar *_titleBar, *_titleBarBackground;
    IBOutlet UITextField* _searchField;
    IBOutlet UILabel* _titleLabel;
    IBOutlet SQShimmerView* _shimmerView;
    
    NSTimer* _statusDisplayUpdater;
    
    NSTimer* _updater;
    
    NSTimeInterval _tapStartTime;
    
    IBOutlet UIView* _squawkListPadding;
    
    IBOutlet UIView* _squawkBarContainer;
    
    BOOL _didRefreshDuringPull;
    
    UIButton* _pushNotificationAdvert;
    
    IBOutlet UILabel* _pullToRefreshLabel;
}

@property(nonatomic)BOOL searchMode;
@property(strong)NSString* searchQuery;
@property(nonatomic)BOOL inviteFriendsPromptVisible;

@end

@implementation SQMainViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
    
    self.view.tintColor = [SQTheme red];//[UIColor colorWithWhite:0.8 alpha:0.4];

    [_squawkBar layoutIfNeeded];
    
    _searchField.placeholder = NSLocalizedString(@"Search", @"Search bar placeholder");
    //_squawkBar.alpha = 0;
    
    //_squawkListPadding.hidden = YES;
    
    _squawksReloadAutomatically.text = NSLocalizedString(@"Relax, Squawks reload automically.", @"").lowercaseString;
    
    self.inviteFriendsPromptVisible = NO;
    
    self.audioActionQueue = [NSMutableArray new];
    
    _pushNotificationAdvert = [UIButton buttonWithType:UIButtonTypeCustom];
    [_pushNotificationAdvert setTitle:NSLocalizedString(@"Tap to enable push notifications", @"") forState:UIControlStateNormal];
    [_pushNotificationAdvert setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_pushNotificationAdvert.titleLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:13]];
    RAC(_pushNotificationAdvert, hidden) = RACObserve(AppDelegate, pushNotificationsEnabled);
    [_pushNotificationAdvert addTarget:self action:@selector(enablePush:) forControlEvents:UIControlEventTouchUpInside];
#ifdef PRETTIFY
    _pushNotificationAdvert.alpha = 0;
#endif
    
    RAC(_titleLabel, text) = [RACObserve(AppDelegate, globalProperties) map:^id(NSDictionary* props) {
        return props[@"title"]? : NSLocalizedString(@"this is Squawk", @"Default main screen title");
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
    
    self.searchMode = NO;
    
    RAC(self, searchQuery) = [[RACSignal combineLatest:@[RACObserve(self, searchMode), _searchField.rac_textSignal] reduce:^id(NSNumber* inSearchMode, NSString* searchQuery){
        return inSearchMode.boolValue? searchQuery : nil;
    }] throttle:0.1];
    
    RAC(_shimmerView, shimmering) = RACObserve(self, loading);
    
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
    
    self.lateEnoughToShowError = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.lateEnoughToShowError = YES;
    });
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
    if ([SQAPI currentPhone]!=nil && self.presentedViewController==nil) {
        [self requestPermissions];
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
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.tableView.frame.size.height-_squawkBar.frame.size.height-64, 0);
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
        return [SQThread makeThreadsFromRecentSquawks:squawks contacts:contacts];
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
            [self.tableView reloadData];
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
        NSString* mostRecentThreadIdentifier = [[self.threadSections.firstObject firstObject] identifier];
        if (![mostRecentThreadIdentifier isEqualToString:_mostRecentThreadIdentifier]) {
            if (!CGPointEqualToPoint(self.tableView.contentOffset, SQDefaultContentOffset)) {
                [self.tableView setContentOffset:SQDefaultContentOffset animated:!!_mostRecentThreadIdentifier];
                _squawkListPadding.hidden = NO;
            }
            _mostRecentThreadIdentifier = mostRecentThreadIdentifier;
        }
    }];
}
-(void)setupErrorMessaging {
    //RACSignal* pushStatus = RACObserve(AppDelegate, registeredForPushNotifications);
    RACSignal* microphoneAuth = RACObserve(AppDelegate, hasRecordPermission);
    RACSignal* fetchError = RACObserve([SQSquawkCache shared], error);
    RACSignal* contactsStatus = RACObserve(self, contactsAuthorization);
    RACSignal* volume = RACObserve(((AVAudioSession*)[AVAudioSession sharedInstance]), outputVolume);
    RACSignal* lateEnough = RACObserve(self, lateEnoughToShowError);
    RAC(_errorLabel, text) = [[[RACSignal combineLatest:@[microphoneAuth, fetchError, contactsStatus, volume, lateEnough]] map:^id(id value) {
        if (!self.lateEnoughToShowError) return @"";
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
    cell.thread = [self threadForIndexPath:indexPath];
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
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    rect.origin.y = (floor(rect.origin.y)/70)*70-64;
    [self.tableView setContentOffset:rect.origin animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _pullToRefreshAnimation.speed = 0;
        _pullToRefreshAnimation.animationTime = 0;
        _pullToRefreshAnimation.alpha = 0;
        _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _pullToRefreshAnimation.speed = 0;
    _pullToRefreshAnimation.animationTime = 0;
    _pullToRefreshAnimation.alpha = 0;
    _pullToRefreshLabel.text = NSLocalizedString(@"Pull to refresh", @"").lowercaseString;
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_searchField resignFirstResponder];
    
    _didRefreshDuringPull = NO;
    
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[SQThreadCell class]]) {
            [(SQThreadCell*)cell scrolled];
        }
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_didRefreshDuringPull) {
        CGFloat pullProgress = -scrollView.contentOffset.y / PULL_TO_REFRESH_THRESHOLD;
        pullProgress = MIN(1, MAX(0, pullProgress));
        NSTimeInterval targetTime = pullProgress*M_PI*2;
        if (targetTime != _pullToRefreshAnimation.animationTime) {
            _pullToRefreshAnimation.animationTime = targetTime;
            _pullToRefreshAnimation.alpha = pullProgress;
            if (pullProgress == 1) {
                _didRefreshDuringPull = YES;
                _pullToRefreshAnimation.speed = 6;
                [[SQSquawkCache shared] fetch];
                _pullToRefreshLabel.text = NSLocalizedString(@"Refreshing", @"").lowercaseString;
            }
        }
    }
    
#ifdef TOP_BAR_SCROLLS
    _headerTopOffset.constant = MIN(0, -scrollView.contentOffset.y);
#endif
}
-(NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"delete squawks", @"");
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    SQThreadCell* cell = (id)[tableView cellForRowAtIndexPath:indexPath];
    SQThread* thread = cell.thread;
    return thread.unread.count>0;
}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.view.userInteractionEnabled = NO;
        SQThreadCell* cell = (id)[tableView cellForRowAtIndexPath:indexPath];
        SQThread* thread = cell.thread;
        NSTimeInterval totalTime = thread.unread.count==1? 0.1 : 1.0;
        [SQThread deleteSquawks:thread.unread intervalBetweenEach:totalTime/thread.unread.count];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((totalTime+0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView setEditing:NO animated:YES];
            self.view.userInteractionEnabled = YES;
        });
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = _pushNotificationAdvert.hidden? 15 : 30;
    if (section==1) return height;
    if (section==0 || section >= self.threadSections.count || [self.threadSections[section] count]==0) {
        return 0;
    }
    return height;
}
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    v.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.000];
    
    UIView* top = [UIView new];
    top.backgroundColor = [UIColor colorWithRed:0.784 green:0.780 blue:0.800 alpha:1];
    [v addSubview:top];
    top.frame = CGRectMake(0, 0, 10, 0.5);
    top.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    
    UIView* bottom = [UIView new];
    bottom.backgroundColor = [UIColor colorWithRed:0.784 green:0.780 blue:0.800 alpha:1];
    [v addSubview:bottom];
    bottom.frame = CGRectMake(0, 9, 10, 1);
    bottom.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    
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
    RACSignal* onScroll = RACObserve(self.tableView, contentOffset);
    RAC(self, selectedThread) = [[[[RACSignal combineLatest:@[onScroll, _tableViewReloaded]] throttle:0.01] map:^id(id value) {
        CGFloat y = _selectorBar.frame.origin.y + _selectorBar.frame.size.height/2;
        for (SQThreadCell* cell in self.tableView.visibleCells) {
            CGRect cellFrame = [self.view convertRect:cell.bounds fromView:cell];
            if (y >= cellFrame.origin.y && y <= cellFrame.origin.y+cellFrame.size.height) {
                return cell.thread;
            }
        }
        return nil;
    }] distinctUntilChanged];
    
    RAC(self, interactingWithThread) = [RACSignal combineLatest:@[RACObserve(self, selectedThread), RACObserve(self, pressedThread)] reduce:^id(SQThread* selected, SQThread* pressed){
        if (pressed) return pressed;
        return selected;
    }];
    
    UIColor* playbackColor = [SQTheme blue];
    UIColor* recordingColor = [SQTheme red];
    
    RACSignal* squawkUpdateSignal = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:SQThreadUpdatedNotification object:nil] startWith:nil];
    [[RACSignal combineLatest:@[RACObserve(self, interactingWithThread), squawkUpdateSignal, [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:SQCheckmarkVisibleNextToThreadIdentifier observer:nil]]] subscribeNext:^(id x) {
        
        if (_interactingWithThread==nil) {
            [_squawkBar setShowsInviteLabel:NO allowsPlackback:NO showsCheckmark:NO playbackLabel:nil recordLabel:nil];
            return;
        }
        
        NSDictionary* mainAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Demibold" size:13], NSForegroundColorAttributeName: [UIColor whiteColor]};
        NSDictionary* subtitleAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:12], NSForegroundColorAttributeName: [UIColor whiteColor]};
        
        NSString* firstName = self.interactingWithThread.veryShortName;
        
        BOOL playback = self.interactingWithThread.unread.count>0;
        BOOL raiseToSquawkAvailable = [WSEarSensor shared].isAvailable;
#ifdef PRETTIFY
        raiseToSquawkAvailable = YES;
#endif
        
        NSMutableAttributedString* playbackTitle = [NSMutableAttributedString new];
        NSMutableAttributedString* recordTitle = [NSMutableAttributedString new];
        if (raiseToSquawkAvailable) {
            [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Raise to ear to listen to %@", @""), firstName] attributes:mainAttributes]];
            [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nor tap and hold", @"") attributes:subtitleAttributes]];
            
            [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Raise to ear to squawk %@", @""), firstName] attributes:mainAttributes]];
            [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"\nor tap and hold", @"") attributes:subtitleAttributes]];
        } else {
            [playbackTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Push to listen to %@", @""), firstName] attributes:mainAttributes]];
            
            [recordTitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Push to squawk %@", @""), firstName] attributes:mainAttributes]];
        }
        BOOL showInviteLabel = !_interactingWithThread.compData->_registered;
        NSString* identifierForCheckmark = [x third];
        BOOL showCheckmark = !!_interactingWithThread && [identifierForCheckmark isEqualToString:[_interactingWithThread identifier]];
        [_squawkBar setShowsInviteLabel:showInviteLabel allowsPlackback:playback showsCheckmark:showCheckmark playbackLabel:playbackTitle recordLabel:recordTitle];
        
        if (playback) {
            [_squawkBar showPlayback:YES];
        }
    }];
    
    RAC(self.view, tintColor) = [RACObserve(_squawkBar, showingPlayback) map:^id(id value) {
        if ([value boolValue]) {
            return playbackColor;
        } else {
            return recordingColor;
        }
    }];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil] subscribeNext:^(id x) {
        [self clearAudioActionQueue];
    }];
    
    RAC(self, playOrRecord) = [[RACSignal combineLatest:@[RACObserve(self, tapDown), RACObserve([WSEarSensor shared], isRaisedToEar), RACObserve(self, pressedThread)] reduce:^id(NSNumber* tapDown, NSNumber* raisedToEar, SQThread* pressedThread){
        return @((tapDown.boolValue || raisedToEar.boolValue || !!pressedThread) && self.presentedViewController==nil);
    }] deliverOn:[RACScheduler mainThreadScheduler]];
}
#pragma mark Squawk bar delegate methods
-(void)playbackOrRecordHeldDown:(SQSquawkBar*)squawkBar {
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _squawkBarContainer.transform = CGAffineTransformMakeTranslation(0, 5);
        _squawkBarContainer.alpha = 0.7;
    } completion:nil];
    _tapStartTime = [NSDate timeIntervalSinceReferenceDate];
    self.tapDown = YES;
}
-(void)playbackOrRecordPickedUp:(SQSquawkBar*)squawkBar {
    if ([NSDate timeIntervalSinceReferenceDate] - _tapStartTime < 1 && ![WSEarSensor shared].isRaisedToEar) {
        SQStatusViewCard* status = [[SQStatusViewCard alloc] initWithText:NSLocalizedString(@"Tap and hold", @"") image:[UIImage imageNamed:@"down-thin"]];
        [_statusView flashStatusView:status duration:2.5];
    }
    self.tapDown = NO;
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _squawkBarContainer.transform = CGAffineTransformMakeTranslation(0, 0);
        _squawkBarContainer.alpha = 1;
    } completion:nil];
}
-(void)playbackOrRecordCancelled:(SQSquawkBar*)squawkBar {
    [self playbackOrRecordPickedUp:squawkBar];
}
-(void)sendCheckmark:(SQSquawkBar*)squawkBar {
    NSString* threadIdentifier = self.interactingWithThread.squawks.firstObject[@"thread_identifier"]? : @"";
    NSMutableArray* sendCheckmarksToPhones = self.interactingWithThread.phoneNumbers.allObjects.mutableCopy;
    [sendCheckmarksToPhones removeObject:[SQAPI currentPhone]];
    [SQAPI post:@"/send_checkmark" args:@{@"recipients": sendCheckmarksToPhones, @"thread_identifier": threadIdentifier} data:nil callback:^(NSDictionary *result, NSError *error) {
        if (![result[@"success"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppDelegate toast:NSLocalizedString(@"Couldn't send checkmark.", @"")];
            });
        }
    }];
    [AppDelegate trackEventWithCategory:@"action" action:@"sent_checkmark" label:nil value:nil];
    
}
-(void)inviteFriend:(SQSquawkBar*)squawkBar {
    [[SQFriendsOnSquawk shared] sendInvitationMessage:[SQFriendsOnSquawk genericInvitationPrompt] toPhones:self.interactingWithThread.numbersToDisplay];
}
-(void)setPlayOrRecord:(BOOL)playOrRecord {
    if (_playOrRecord == playOrRecord) return;
    _playOrRecord = playOrRecord;
    if (playOrRecord) {
        if (self.interactingWithThread) {
            if ([WSEarSensor shared].isRaisedToEar) {
                self.interactionMode = SQRaisedToEar;
            } else if (self.pressedThread) {
                self.interactionMode = SQPressedRow;
            } else {
                self.interactionMode = SQPressedButton;
            }
            
            // log stuff:
            BOOL playback = self.squawkBar.showingPlayback;
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
        self.interactionMode = SQNoInteraction;
        [self clearAudioActionQueue];
    }
}
#pragma mark Header/search
-(void)setSearchMode:(BOOL)searchMode {
    if (searchMode != _searchMode) {
        [self.tableView setContentOffset:CGPointZero];
    }
    _searchMode = searchMode;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:(searchMode? 0.5 : 1) initialSpringVelocity:0 options:0 animations:^{
        _searchBarTopOffset.constant = searchMode? -8 : 50;
        [self.view layoutIfNeeded];
        _titleLabel.alpha = searchMode? 0 : 1;
    } completion:^(BOOL finished) {
        
    }];
    _searchField.text = @"";
    self.searchQuery = @"";
    if (searchMode) {
        [_searchField becomeFirstResponder];
    } else {
        [_searchField resignFirstResponder];
    }
    
    UIBarButtonItem* leftButton = searchMode? [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exitSearchMode:)] : [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(enterSearchMode:)];
    UIBarButtonItem* rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newThread:)];
    [_titleBar.items.lastObject setLeftBarButtonItem:leftButton animated:YES];
    [_titleBar.items.lastObject setRightBarButtonItem:rightButton];
    [_titleBar.items.lastObject setTitle:@""];
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
    RAC(_statusView, passthroughRects) = [[[[RACSignal combineLatest:@[RACObserve(self, interactingWithThread), RACObserve(self.tableView, contentOffset)] reduce:^id(SQThread* thread, CGPoint offset){
        SQThreadCell* cell = [self cellForThread:thread];
        if (cell) {
            return @[[NSValue valueWithCGRect:[_statusView convertRect:cell.bounds fromView:cell]]];
        } else {
            return nil;
        }
    }] filter:^BOOL(id value) {
        return [value count]>0;
    }] distinctUntilChanged] deliverOn:[RACScheduler mainThreadScheduler]];
    
    [[RACObserve(self, currentAudioAction) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        if (x && !_statusDisplayUpdater) {
            _statusDisplayUpdater = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateStatusDisplay) userInfo:nil repeats:YES];
        } else if (x==nil && _statusDisplayUpdater) {
            [_statusDisplayUpdater invalidate];
            _statusDisplayUpdater = nil;
        }
        
        SQStatusViewCard* newStatusView = [self nextStatusView];
        [_statusView replaceStatusViewForIdentifier:@"currentAudioAction" withStatusView:newStatusView];
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
    SQStatusViewCard* status = [[SQStatusViewCard alloc] initWithText:NSLocalizedString(@"Sent.", @"") image:[UIImage imageNamed:@"ok-thin"]];
    [_statusView flashStatusView:status duration:self.interactionMode==SQRaisedToEar? 2.5 : 1];
    
    [[SQSquawkCache shared] performSelector:@selector(pollIfNeeded) withObject:nil afterDelay:1.0];
}
#pragma mark Misc.
-(void)enablePush:(id)sender {
    UIViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PushEnableDialog"];
    [vc presentSoftModalInViewController:self];
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

@end
