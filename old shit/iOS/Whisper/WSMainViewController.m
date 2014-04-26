//
//  WSMainViewController.m
//  Whisper
//
//  Created by Nate Parrott on 1/22/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSMainViewController.h"
#import "ConvenienceCategories.h"
#import "WSAppDelegate.h"
#import "WSFriendsOnSquawk.h"
#import "NSString+NormalizeForSearch.h"
#import "WSSquawkRecorder.h"
#import "WSPersistentDictionary.h"
#import "WSIndividualSquawkerCell.h"
#import "WSMultisquawkCellTableViewCell.h"
#import "WSAppDelegate+GlobalUIExtensions.h"
#import "RACSignal+MustStayTrue.h"
#import "WSThreadSender.h"
#import "WSEarSensor.h"
#import "WSContactBoost.h"
#import "NSArray+Diff.h"

#define MULTISQUAWK_PULL_THRESHOLD (56+STATUS_BAR_TRANSLUCENT_HEIGHT)

#define STATUS_BAR_TRANSLUCENT_HEIGHT 0

#define CACHE_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"cache"]

NSString* WSContentDidReload = @"kWSContentDidReload";

@interface WSMainViewController ()

@end

@implementation WSMainViewController

#pragma mark ViewController shit
-(void)viewDidLoad {
    [super viewDidLoad];
    
    _focusTriangleInitialTopOffset = 14.5;
    [self setFocusTriangleTopOffset:14.5];
    
    _lastActiveCellState = -1;
    
    [AppDelegate registerForPushNotifications];
    
    [[AppDelegate globalProperties] subscribeNext:^(NSDictionary* props) {
        NSString* title = props[@"title"]? : NSLocalizedString(@"this is Squawk", @"Main title");
#ifndef TAKING_DEFAULT_IMAGE
        self.navigationItem.title = title;
#endif
    }];
    
    
#ifdef TAKING_DEFAULT_IMAGE
    self.navigationItem.title = nil;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
#endif
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"Avenir-Heavy" size:18], NSForegroundColorAttributeName: [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.000]};
    
    _searchQuery = [RACReplaySubject replaySubjectWithCapacity:1];
    [_searchQuery sendNext:@""];
    
    _contacts = [RACReplaySubject replaySubjectWithCapacity:1];
    [NPAddressBook getAuthorizedAddressBookWithCallback:^(NPAddressBook *book) {
        if (!_addressBook) {
            _addressBook = book;
            NSArray* allContacts = [_addressBook.allContacts map:^id(id obj) {
                return [obj phoneNumbers].count? obj : nil;
            }];
            [_contacts sendNext:allContacts];
            [[[NSNotificationCenter defaultCenter] rac_addObserverForName:(id)NPAddressBookDidChangeNotification object:_addressBook] subscribeNext:^(id x) {
                [_contacts sendNext:_addressBook.allContacts];
            }];
        }
    }];
    
    [_contacts subscribeNext:^(id x) {
        [[WSFriendsOnSquawk manager] updateIfNecessaryUsingContactsList:x];
    }];
    
    _activeCellState = [RACReplaySubject replaySubjectWithCapacity:1];
    [self cellStateUpdated];
    RACSignal* cellState = [_activeCellState distinctUntilChanged];
    
    [cellState subscribeNext:^(id x) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:[x integerValue]!=WSCellStateSilent];
    }];
    
    _currentUser = [RACReplaySubject replaySubjectWithCapacity:1];
    [_currentUser sendNext:[PFUser currentUser]];
    
    RACSignal* reloadMessages = [[RACSignal combineLatest:
      @[_currentUser,
        [[AppDelegate appOpened] startWith:nil],
        [[AppDelegate messageNotifications] startWith:nil]]] throttle:0.1];
    
    RACSignal* latestRecentMessagesOrError = [[[[reloadMessages flattenMap:^id(id value) {
        if ([AppDelegate currentUser]==nil) {
            RACSubject* sub = [RACSubject subject];
            return sub;
        }
        RACSubject* sub = [RACSubject subject];
        PFQuery* query = [PFQuery queryWithClassName:@"Message"];
        query.cachePolicy = kPFCachePolicyNetworkOnly;
        [query whereKey:@"recipient" equalTo:[PFUser currentUser]];
        [query orderByDescending:@"createdAt"];
        //[query selectKeys:@[@"id2", @"sender", @"listened", @"file", @"threadMembers"]];
        [query includeKey:@"sender"];
        [query includeKey:@"threadMembers"];
        if (_recentSquawks.count) {
            [query whereKey:@"createdAt" greaterThanOrEqualTo:[_recentSquawks.firstObject valueForKey:@"createdAt"]];
        }
        [query setLimit:20];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!_recentSquawks) _recentSquawks = [NSMutableArray new];
            NSSet* existingObjectIds = [NSSet setWithArray:[_recentSquawks map:^id(id obj) {
                return [obj objectId];
            }]];
            for (int i=0; i<objects.count; i++) {
                PFObject* msg = objects[i];
                if (![existingObjectIds containsObject:msg.objectId]) {
                    [_recentSquawks insertObject:msg atIndex:i];
                }
            }
            while (_recentSquawks.count > 30) [_recentSquawks removeLastObject];
            
            if (!error) {
                [sub sendNext:_recentSquawks.copy];
            } else {
                [sub sendNext:error];
            }
            [sub sendCompleted];
        }];
        return sub;
    }] distinctUntilChanged] publish] autoconnect];
    
    // this is either an array of sender objects, or an NSError:
    RACSignal* sendersOrError = [[[[[RACSignal combineLatest:
                                   @[
                                     latestRecentMessagesOrError,
                                     _contacts,
                                     [WSFriendsOnSquawk manager].phoneNumbersOfFriendsOnSquawkSignal,
                                     [WSContactBoost updateSignal]
                                     ]] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] reduceEach:^id(id messagesOrError, id contactsOrNil, NSSet* friendsOnSquawk, id contactBoosts)
    {
        if ([messagesOrError isKindOfClass:[NSError class]]) {
            NSError* e = [[NSError alloc] initWithDomain:WSErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Couldn't connect to the Internet.", @"")}];
            return e;
        }
        if (!contactsOrNil) {
            NSError* e = [[NSError alloc] initWithDomain:WSErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Squawk doesn't have access to your contacts. Give Squawk access in the Settings app, under Privacy.", @"")}];
            return e;
        }
        return [self makeSenderObjectsFromMessages:messagesOrError contacts:contactsOrNil];
    }] publish] autoconnect];
    
    [sendersOrError subscribeNext:^(id x) {
        [[WSMainViewController mostRecentSendersOrError] sendNext:x];
    }];
    
    RACSignal* filteredSendersOrError = [[[[[RACSignal combineLatest:@[sendersOrError, _searchQuery]] throttle:0.5] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] reduceEach:^id(id sendersOrError, NSString* query) {
        if ([sendersOrError isKindOfClass:[NSArray class]]) {
            return [self filterSenderObjects:sendersOrError withSearchQuery:query];
        } else {
            return sendersOrError; // probably an error
        }
    }] deliverOn:[RACScheduler mainThreadScheduler]];
    
    RACSignal* displayWhenAllowed = [[[RACSignal combineLatest:@[filteredSendersOrError, cellState] reduce:^id(id sendersOrError, NSNumber* cellState){
        return cellState.integerValue==WSCellStateSilent? sendersOrError : nil;
    }] filter:^BOOL(id value) {
        return !!value;
    }] distinctUntilChanged];
    [displayWhenAllowed subscribeNext:^(id x) {
        [self updateDisplay:x];
    }];
    
    [self setupPermissionsAndWarnings];
    
    [self setupAudioSession];
    
    _multisquawkControlRow = [[WSSingleCellTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 70) style:UITableViewStylePlain];
    _multisquawkControlRow.nibName = @"WSMultisquawkCell";
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:WSShouldQuitMultisquawkMode object:nil] subscribeNext:^(id x) {
        self.multisquawkMode = NO;
    }];
    _multisquawkControlRow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_multisquawkControlRow];
    /*RAC(_multisquawkControlRow, frame) = [RACSignal combineLatest:@[RACObserve(self.tableView, contentOffset), RACObserve(self, multisquawkMode)] reduce:^id(NSValue* offset, NSNumber* multisquawkMode){
        CGFloat y = 0 - ([offset CGPointValue].y+70);
        if (multisquawkMode.boolValue) {
            y = MAX(64, y);
        }
        return [NSValue valueWithCGRect:CGRectMake(0, y, self.view.bounds.size.width, 70)];
    }];*/
    RACSignal* multisquawkTurnedOn = [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:WSMultisquawkEnabled observer:self];
    RAC(_multisquawkControlRow, alpha) = [RACSignal combineLatest:@[RACObserve(self, multisquawkMode), RACObserve(self.tableView, contentOffset), multisquawkTurnedOn] reduce:^id(NSNumber* multisquawkEnabled, NSValue* contentOffset, NSNumber* turnedOn){
        if (turnedOn.boolValue==NO) return @0;
        return @(multisquawkEnabled.boolValue? 1 : MAX(0, (STATUS_BAR_TRANSLUCENT_HEIGHT-contentOffset.CGPointValue.y)/MULTISQUAWK_PULL_THRESHOLD));
    }];
    
    self.tableView.contentInset = UIEdgeInsetsMake(STATUS_BAR_TRANSLUCENT_HEIGHT, 0, 0, 0);
    
    //_manuallyFocusedCell = [RACSubject subject];
    
    _activeCell = [RACReplaySubject replaySubjectWithCapacity:1];
    [_activeCell sendNext:nil];
    /*self.focusedCell = [[[[[RACSignal combineLatest:@[
                                                      RACObserve(self, multisquawkMode),
                                                      RACObserve(self, contentOffset),
                                                      displayWhenAllowed,
                                                      RACObserve(self, focusTriangleTopOffset),
                                                      _activeCell,
                                                      [_manuallyFocusedCell startWith:nil]
                                                      ]] map:^id(id _){
        if (self.multisquawkMode) {
            return _multisquawkControlRow.visibleCells.firstObject;
        } else {
            if (_activeCell.first) {
                return _activeCell.first;
            } else {
                CGFloat focusY = [self.view convertPoint:_focusTriangle.center fromView:_focusTriangle.superview].y;
                for (WSSquawkerCell* cell in self.tableView.visibleCells) {
                    CGRect rect = [self.view convertRect:cell.bounds fromView:cell];
                    if (focusY >= rect.origin.y && focusY < rect.origin.y+rect.size.height) {
                        return cell;
                    }
                }
                return nil;
            }
        }
    }] distinctUntilChanged] publish] autoconnect];*/
    
    RACSignal* raiseToSquawkEnabled = [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:WSRaiseToSquawkEnabled observer:self];
    
    self.cellForRaiseToSquawk = [[[[RACObserve([WSEarSensor shared],  isRaisedToEar) map:^id(NSNumber* raisedToEar) {
        if (raisedToEar.boolValue && [[NSUserDefaults standardUserDefaults] boolForKey:WSRaiseToSquawkEnabled]) {
            if (_activeCell.first) {
                return _activeCell.first;
            } else {
                CGFloat focusY = [self.view convertPoint:_focusTriangle.center fromView:_focusTriangle.superview].y;
                for (WSSquawkerCell* cell in self.tableView.visibleCells) {
                    CGRect rect = [self.view convertRect:cell.bounds fromView:cell];
                    if (focusY >= rect.origin.y && focusY < rect.origin.y+rect.size.height) {
                        return cell;
                    }
                }
                return nil;
            }
        } else {
            return nil;
        }
    }]  deliverOn:[RACScheduler mainThreadScheduler]] publish] autoconnect];
    
    //self.raisedToEar = [RACObserve([UIDevice currentDevice], proximityState) mustStayTrueFor:0.75];
    //self.raisedToEar = [[RACSignal combineLatest:@[RACObserve([WSEarSensor shared], isRaisedToEar), raiseToSquawkEnabled]] and];
    
    RAC(_focusTriangle, hidden) = [[[RACSignal combineLatest:@[RACObserve([WSEarSensor shared], isAvailable), raiseToSquawkEnabled]] and] not];
    [self.view bringSubviewToFront:_focusTriangle];
    
    [[AppDelegate didLaunchWithNotification] subscribeNext:^(id x) {
        [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top) animated:YES];
    }];
    
    RAC(self.tableView, scrollEnabled) = [[[[_activeCell map:^id(id value) {
        return @(value!=nil);
    }] mustStayTrueFor:0.5] startWith:@NO] not];
    
    [latestRecentMessagesOrError subscribeNext:^(id x) {
        if ([x isKindOfClass:[NSArray class]]) {
            int unread = 0;
            for (PFObject* message in x) {
                if (![WSSquawkerCell hasSquawkBeenListenedTo:message]) {
                    unread++;
                }
            }
            [WSSquawkerCell gotUnreadCount:unread];
        }
    }];
}
-(void)setupPermissionsAndWarnings {
    _microphoneAuthorization = [RACReplaySubject replaySubjectWithCapacity:1];
    [_microphoneAuthorization sendNext:WSAuthorizationUnknown];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [_microphoneAuthorization sendNext:granted? WSAuthorizationGranted : WSAuthorizationDenied];
    }];
    
    // permission-denied warnings:
    RACSignal* microphoneWarning = [_microphoneAuthorization map:^id(id value) {
        return [value isEqualToString:WSAuthorizationDenied]? NSLocalizedString(@"You haven't given Squawk access to your microphone. Do this in the Settings app, under Privacy.", @"") : nil;
    }];
    RACSignal* pushWarning = [[AppDelegate pushAuthorization] map:^id(id value) {
#ifdef TARGET_IPHONE_SIMULATOR
        return nil; // push is always off in the simulator, so no use displaying a warning
#endif
        return [value isEqualToString:WSAuthorizationDenied]? NSLocalizedString(@"You've turned off notifications for Squawk. Enable them in the Settings app, under notifications.", @"") : nil;
    }];
    RACSignal* volume = RACObserve(((AVAudioSession*)[AVAudioSession sharedInstance]), outputVolume);
    RACSignal* volumeWarning = [RACSignal combineLatest:@[volume, _activeCellState] reduce:^id(NSNumber* volume, NSNumber* cellState) {
        if (volume.floatValue>0 || cellState.integerValue==WSCellStateRecording) {
            return nil;
        } else {
            return NSLocalizedString(@"Your volume is zero. You won't hear Squawks.", @"");
        }
    }];
    RACSignal* warningMessages = [[RACSignal combineLatest:@[microphoneWarning, pushWarning, volumeWarning]] map:^id(RACTuple* messages) {
        return [[[messages.rac_sequence filter:^BOOL(id value) {
            return ![value isKindOfClass:[NSNull class]];
        }] array] componentsJoinedByString:@"\n\n"];
    }];
    RAC(self.warningMessageLabel, text) = warningMessages;
    RAC(self.warningMessageContainer, hidden) = [warningMessages map:^id(id value) {
        return @([value length]==0);
    }];
}
-(void)setupAudioSession {
    RACSignal* proximityStateChanged = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIDeviceProximityStateDidChangeNotification object:[UIDevice currentDevice]] startWith:nil];
    [[RACSignal combineLatest:@[[[AppDelegate appOpened] startWith:nil], proximityStateChanged]] subscribeNext:^(id x) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        UInt32 doChangeDefaultRoute = [UIDevice currentDevice].proximityState? 0 : 1;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }];
    /*RAC([UIDevice currentDevice], proximityMonitoringEnabled) = [_activeCellState map:^id(id value) {
        return @([value integerValue]==WSCellStatePlayback);
    }];*/
}
-(void)cancelAllBut:(WSSquawkerCell*)ignore {
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if (cell != ignore && [cell isKindOfClass:[WSSquawkerCell class]]) {
            [(WSSquawkerCell*)cell cancel];
        }
    }
}
-(BOOL)automaticallyAdjustsScrollViewInsets {
    return NO;
}
#pragma mark Data
-(NSArray*)makeSenderObjectsFromMessages:(NSArray*)messages contacts:(NSArray*)contacts {
    NSMutableArray* senders = [NSMutableArray new];
    
    NSMutableDictionary* sendersForParticipantIdentifiers = [NSMutableDictionary new];
    for (NPContact* person in contacts) {
        WSMessageSender* sender = [WSMessageSender new];
        sender.contact = person;
        [senders addObject:sender];
        for (NSString* number in person.phoneNumbers) {
            sendersForParticipantIdentifiers[number] = sender;
        }
    }
    for (PFObject* message in messages) {
        id msgIdentifier = [WSMessageSender participantIdentifierForMessage:message];
        WSMessageSender* sender = sendersForParticipantIdentifiers[msgIdentifier];
        if (sender) {
            [sender.messages addObject:message];
        } else {
            WSMessageSender* sender = nil;
            if ([WSMessageSender isMessageThreaded:message]) {
                sender = [WSThreadSender new];
            } else {
                sender = [WSMessageSender new];
            }
            [senders addObject:sender];
            [sender.messages addObject:message];
            if ([WSMessageSender isMessageThreaded:message]) {
                ((WSThreadSender*)sender).contacts = [[sender phoneNumbersToSendTo] map:^id(id num) {
                    WSMessageSender* person = sendersForParticipantIdentifiers[num];
                    return (person && person.contact)? person.contact : nil;
                }];
            }
            sendersForParticipantIdentifiers[msgIdentifier] = sender;
        }
    }
    for (WSMessageSender* sender in senders) {
        [sender generateSearchableName];
    }
    [senders sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        WSMessageSender* c1 = obj1;
        WSMessageSender* c2 = obj2;
        NSTimeInterval c1MostRecent = [c1 dateForSorting];
        NSTimeInterval c2MostRecent = [c2 dateForSorting];
        NSString* name1 = [c1 searchableName];
        NSString* name2 = [c2 searchableName];
        int priority1 = [c1 isRegistered]? 1 : 0;
        int priority2 = [c2 isRegistered]? 1 : 0;
        return (c2MostRecent-c1MostRecent)? : (priority2 - priority1)? : [name1 compare:name2];
    }];
    [senders filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id sender, NSDictionary *bindings) {
        return [sender phoneNumbers].count > 0;
    }]];
    return senders;
}
-(NSArray*)filterSenderObjects:(NSArray*)senders withSearchQuery:(NSString*)search {
    if (search.length == 0) {
        return senders;
    } else {
        search = [search normalizedForSearch];
        return [senders map:^id(id obj) {
            NSString* name = [obj searchableName];
            if ([name rangeOfString:search].location!=NSNotFound) {
                return obj;
            }
            return nil;
        }];
    }
}
-(NSArray*)phoneNumbersForFriendsOnSquawk {
    return [[_senders.rac_sequence filter:^BOOL(id value) {
        return [value isRegistered];
    }] map:^id(id value) {
        return [value preferredPhoneNumber];
    }].array;
}
#pragma mark Display
-(void)updateDisplay:(id)sendersOrError {
    if ([sendersOrError isKindOfClass:[NSArray class]]) {
        if (_senders && 0) { // disable animation
            NSArray* diffs = [_senders diffsWithArray:sendersOrError comparator:^BOOL(id a, id b) {
                return [a isEquivalentTo:b];
            }];
            [self.tableView beginUpdates];
            int insertionOffset = 0;
            NSMutableSet* inserted = [NSMutableSet new];
            for (NSArrayDiff* diff in diffs) {
                NSMutableArray* delete = [NSMutableArray new];
                for (int i=diff.range.location; i<diff.range.location+diff.range.length; i++) {
                    [delete addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                NSMutableArray* insert = [NSMutableArray new];
                for (int i=diff.range.location; i<diff.range.location+diff.insertedObjects.count; i++) {
                    [insert addObject:[NSIndexPath indexPathForRow:i+insertionOffset inSection:0]];
                    [inserted addObject:insert.lastObject];
                }
                insertionOffset += diff.insertedObjects.count - diff.range.length;
                [self.tableView deleteRowsAtIndexPaths:delete withRowAnimation:UITableViewRowAnimationTop];
                [self.tableView insertRowsAtIndexPaths:insert withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            _senders = [sendersOrError mutableCopy];
            [self.tableView endUpdates];
            
            [self.tableView reloadRowsAtIndexPaths:[self.tableView.indexPathsForVisibleRows map:^id(id obj) {
                return [inserted containsObject:obj]? nil : obj;
            }] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            _senders = [sendersOrError mutableCopy];
            [self.tableView reloadData];
        }
    } else if ([sendersOrError isKindOfClass:[NSError class]]) {
        _senders = nil;
        _displayError = sendersOrError;
        [self.tableView reloadData];
    }
    self.errorLabel.text = _displayError.localizedDescription;
}
#pragma mark TableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#ifdef TAKING_DEFAULT_IMAGE
    return 0;
#endif
    return _senders.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.multisquawkMode) {
        UITableViewCell* multisquawkCell = [tableView dequeueReusableCellWithIdentifier:@"MultisquawkCell" forIndexPath:indexPath];
        WSMessageSender* sender = _senders[indexPath.row];
        BOOL selected = [self isUserSelectedForMultisquawk:sender];
        UILabel* nameLabel = (id)[multisquawkCell viewWithTag:1];
        [nameLabel setAttributedText:[sender attributedLabel]];
        UIImageView* imageView = (id)[multisquawkCell viewWithTag:3];
        imageView.image = [UIImage imageNamed:selected? @"radio-checked" : @"radio-unchecked"];
        nameLabel.alpha = [sender isGroupThread]? 0.5 : 1;
        return multisquawkCell;
    } else {
        WSIndividualSquawkerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        cell.mainVC = self;
        cell.model = _senders[indexPath.row];
        return cell;
    }
}
-(BOOL)isUserSelectedForMultisquawk:(WSMessageSender*)user {
    for (NSString* num in user.phoneNumbers) {
        if ([[WSMultisquawkCellTableViewCell multisquawkSelectedPhoneNumbers] containsObject:num]) return YES;
    }
    return NO;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.multisquawkMode) {
        WSMessageSender* sender = _senders[indexPath.row];
        if ([sender preferredPhoneNumber]) {
            NSMutableSet* nums = [WSMultisquawkCellTableViewCell multisquawkSelectedPhoneNumbers];
            NSString* num = [sender preferredPhoneNumber];
            if ([nums containsObject:num]) {
                [nums removeObject:num];
            } else {
                [nums addObject:num];
            }
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        
    }
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_searchBar resignFirstResponder];
    [self cancelAllBut:nil];
    
    self.focusTriangleTopOffset = _focusTriangleInitialTopOffset;
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y < -MULTISQUAWK_PULL_THRESHOLD && [[NSUserDefaults standardUserDefaults] boolForKey:WSMultisquawkEnabled]) {
        self.multisquawkMode = YES;
    }
    if (!decelerate) {
        self.contentOffset = scrollView.contentOffset;
    }
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[WSSquawkerCell class]]) {
        [(id)cell setVisible:YES];
    }
}
-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[WSSquawkerCell class]]) {
        [(id)cell setVisible:NO];
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.contentOffset = scrollView.contentOffset;
}
-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    self.contentOffset = scrollView.contentOffset;
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat y = 0 - (scrollView.contentOffset.y+70);
    if (_multisquawkMode) {
        y = MAX(STATUS_BAR_TRANSLUCENT_HEIGHT, y);
    }
    _multisquawkControlRow.frame =CGRectMake(0, y, self.view.bounds.size.width, 70);
}
#pragma mark Search
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [_searchQuery sendNext:@""];
    searchBar.text = @"";
}
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [_searchQuery sendNext:searchText];
}

#pragma mark Status
-(void)cellStateUpdated {
    WSCellState state = WSCellStateSilent;
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[WSSquawkerCell class]]) {
            WSSquawkerCell* senderCell = (id)cell;
            if (senderCell.state != WSCellStateSilent) {
                //[self highlightCell:senderCell];
                [_activeCell sendNext:senderCell];
                state = senderCell.state;
            }
        }
    }
    if (state==WSCellStateSilent) {
        [_activeCell sendNext:nil];
    }
    if (state == _lastActiveCellState) return;
    _lastActiveCellState = state;
    [_activeCellState sendNext:@(state)];
}
#pragma mark Multisquawk
-(void)setMultisquawkMode:(BOOL)multisquawkMode {
    if (multisquawkMode == _multisquawkMode) return;
    _multisquawkMode = multisquawkMode;
    
    [_multisquawkControlRow.visibleCells.firstObject setMainVC:self];
    
    [[WSMultisquawkCellTableViewCell multisquawkSelectedPhoneNumbers] removeAllObjects];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(STATUS_BAR_TRANSLUCENT_HEIGHT + (multisquawkMode? 70 : 0), 0, 0, 0);
        
        _multisquawkControlRow.alpha = multisquawkMode? 1 : 0;
        
        CGFloat y = 0 - (self.tableView.contentOffset.y+70);
        if (multisquawkMode) {
            y = MAX(STATUS_BAR_TRANSLUCENT_HEIGHT, y);
        }
        _multisquawkControlRow.frame = CGRectMake(0, y, self.view.bounds.size.width, 70);
    } completion:nil];
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)setFocusTriangleTopOffset:(CGFloat)focusTriangleTopOffset {
    _focusTriangleTopOffset = focusTriangleTopOffset;
    if (_focusTriangleOffsetConstraint.constant == focusTriangleTopOffset) return;
    [_focusTriangleOffsetConstraint setConstant:focusTriangleTopOffset];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}
-(void)highlightCell:(UITableViewCell*)cell {
    UIView* container = self.view;
    CGRect frame = [cell convertRect:cell.bounds toView:container];
    CGFloat y = frame.origin.y + frame.size.height/2;
    y = y - self.tableView.contentInset.top - _focusTriangle.frame.size.height/2;
    [self setFocusTriangleTopOffset:y];
   // [_manuallyFocusedCell sendNext:cell];
    
}
#pragma mark External interface
+(RACReplaySubject*)mostRecentSendersOrError {
    static RACReplaySubject* subj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        subj = [RACReplaySubject replaySubjectWithCapacity:1];
        [subj sendNext:nil];
    });
    return subj;
}

@end
