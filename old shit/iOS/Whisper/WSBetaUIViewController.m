//
//  WSBetaUIViewController.m
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSBetaUIViewController.h"
#import "WSAppDelegate.h"
#import "ConvenienceCategories.h"
#import "WSFriendsOnSquawk.h"
#import "WSMessageSender.h"
#import "NSString+NormalizeForSearch.h"
#import "WSSquawkerView.h"

@interface WSBetaUIViewController ()

@end

@implementation WSBetaUIViewController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 500)];
    self.table = [SQExpandingTableView new];
    [self.view addSubview:self.table];
    self.table.delegate = self;
    self.table.scrollView.delaysContentTouches = YES;
}

-(void)viewDidLoad {
    [super viewDidLoad];
        
    _lastActiveCellState = -1;
    
    [AppDelegate registerForPushNotifications];
    
    _searchBar = [UISearchBar new];
    self.navigationItem.titleView = _searchBar;
    _searchBar.frame = CGRectMake(0, 0, 260, 30);
    _searchBar.placeholder = NSLocalizedString(@"this is Squawk", @"Search field placeholder text");
    _searchBar.delegate = self;
    _searchBar.accessibilityLabel = @"Search contacts";
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Avenir-Heavy" size:16]];
    
    [[AppDelegate globalProperties] subscribeNext:^(NSDictionary* props) {
        _searchBar.placeholder = props[@"title"]? : @"this is Squawk";
        //[[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Avenir-Heavy" size:16]];
    }];
    
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
    
    RAC([UIApplication sharedApplication], idleTimerDisabled) = [cellState map:^id(id value) {
        return @([value integerValue] == WSCellStatePlayback);
    }];
    
    _currentUser = [RACReplaySubject replaySubjectWithCapacity:1];
    [_currentUser sendNext:[PFUser currentUser]];
    
    RACSignal* reloadMessages = [[RACSignal combineLatest:
                                  @[_currentUser,
                                    [[AppDelegate appOpened] startWith:nil],
                                    [[AppDelegate messageNotifications] startWith:nil]]] throttle:0.1];
    
    RACSignal* latestRecentMessagesOrError = [[reloadMessages flattenMap:^id(id value) {
        if ([AppDelegate currentUser]==nil) {
            RACSubject* sub = [RACSubject subject];
            return sub;
        }
        RACSubject* sub = [RACSubject subject];
        PFQuery* query = [PFQuery queryWithClassName:@"Message"];
        query.cachePolicy = kPFCachePolicyNetworkOnly;
        [query whereKey:@"recipient" equalTo:[PFUser currentUser]];
        [query orderByDescending:@"createdAt"];
        [query selectKeys:@[@"id2", @"sender", @"listened", @"file"]];
        [query includeKey:@"sender"];
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
    }] distinctUntilChanged];
    
    [latestRecentMessagesOrError subscribeNext:^(id x) {
        [AppDelegate.lastFetchedRecentSquawkOrError sendNext:x];
    }];
    
    // update badge:
    [[RACSignal combineLatest:@[latestRecentMessagesOrError, cellState]] subscribeNext:^(RACTuple* x) {
        id messages = x.first;
        if ([messages isKindOfClass:[NSArray class]]) {
            int unreadCount = 0;
            for (PFObject* message in messages) {
                if (![WSSquawkerCell hasSquawkBeenListenedTo:message]) {
                    unreadCount++;
                }
            }
            //NSLog(@"updating badge to %i", unreadCount);
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            if (currentInstallation.badge != unreadCount) {
                currentInstallation.badge = unreadCount;
                [currentInstallation saveEventually];
            }
        }
    }];
    
    // this is either an array of sender objects, or an NSError:
    RACSignal* sendersOrError = [[[RACSignal combineLatest:
                                   @[latestRecentMessagesOrError, _contacts, [WSFriendsOnSquawk manager].phoneNumbersOfFriendsOnSquawkSignal] ] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] reduceEach:^id(id messagesOrError, id contactsOrNil, NSSet* friendsOnSquawk)
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
        //NSLog(@"displaying: %@", x);
        _senders = nil;
        _displayError = nil;
        if ([x isKindOfClass:[NSArray class]]) {
            _senders = x;
        } else if ([x isKindOfClass:[NSError class]]) {
            _displayError = x;
        }
        [self updateDisplay];
    }];
    
    [self setupPermissionsAndWarnings];
    
    [self setupAudioSession];
    
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
}
-(void)cellStateUpdated {
    WSCellState state = WSCellStateSilent;
    /*for (UITableViewCell* cell in self.table.cellsForIndices.allValues) {
        if ([cell isKindOfClass:[WSSquawkerCell class]]) {
            WSSquawkerCell* senderCell = (id)cell;
            if (senderCell.state != WSCellStateSilent) {
                state = senderCell.state;
            }
        }
    }*/
    if (state == _lastActiveCellState) return;
    _lastActiveCellState = state;
    [_activeCellState sendNext:@(state)];
}
#pragma mark Data
-(NSArray*)makeSenderObjectsFromMessages:(NSArray*)messages contacts:(NSArray*)contacts {
    NSMutableArray* senders = [NSMutableArray new];
    
    NSMutableDictionary* sendersForPhones = [NSMutableDictionary new];
    for (NPContact* person in contacts) {
        WSMessageSender* sender = [WSMessageSender new];
        sender.contact = person;
        [senders addObject:sender];
        for (NSString* number in person.phoneNumbers) {
            sendersForPhones[number] = sender;
        }
    }
    for (PFObject* message in messages) {
        WSMessageSender* sender = sendersForPhones[[[message valueForKey:@"sender"] valueForKey:@"username"]];
        if (sender) {
            [sender.messages addObject:message];
        } else {
            WSMessageSender* sender = [WSMessageSender new];
            [senders addObject:sender];
            [sender.messages addObject:message];
            NSString* num = sender.preferredPhoneNumber;
            sendersForPhones[num] = sender;
        }
    }
    for (WSMessageSender* sender in senders) [sender generateSearchableName];
    [senders sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        WSMessageSender* c1 = obj1;
        WSMessageSender* c2 = obj2;
        NSDate* c1MostRecent = [c1 latestMessage]? : [NSDate distantPast];
        NSDate* c2MostRecent = [c2 latestMessage]? : [NSDate distantPast];
        NSString* name1 = [c1 searchableName];
        NSString* name2 = [c2 searchableName];
        int priority1 = [c1 isRegistered]? 1 : 0;
        int priority2 = [c2 isRegistered]? 1 : 0;
        return [c2MostRecent compare:c1MostRecent]? : (priority2 - priority1)? : [name1 compare:name2];
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
#pragma mark Layout
-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.table.frame = CGRectMake(0, [[self topLayoutGuide] length], self.view.bounds.size.width, self.view.bounds.size.height-[[self topLayoutGuide] length]);
}
#pragma mark Table
-(void)updateDisplay {
    [self.table reloadAnimated:YES];
}
-(int)numberOfRowsInTableView:(SQExpandingTableView *)tableView {
    return (int)_senders.count;
}
-(CGFloat)heightForCellsInTableView:(SQExpandingTableView *)tableView {
    return 70;
}
-(CGFloat)expandedHeightForCellsInTableView:(SQExpandingTableView *)tableView {
    return 160;
}
-(UIView*)tableView:(SQExpandingTableView *)tableView viewAtIndex:(int)index {
    WSMessageSender* squawker = _senders[index];
    WSSquawkerView* view = nil;
    for (WSSquawkerView* existing in tableView.oldViews) {
        if ([existing.squawker isEqual:squawker]) {
            view = existing;
            [tableView.oldViews removeObject:view];
        }
    }
    if (!view) {
        view = (id)[tableView dequeueViewForReuse];
        if (!view) {
            view = [WSSquawkerView view];
            view.owner = self;
        }
    }
    view.squawker = squawker;
    view.expanded = NO;
    return view;
}
-(void)tableView:(SQExpandingTableView *)tableView willExpandViewAtIndex:(int)index {
    WSSquawkerView* expanded = tableView.cellsForIndices[@(index)];
    for (WSSquawkerView* view in tableView.cellsForIndices.allValues) {
        if (view!=expanded) view.expanded = NO;
    }
    expanded.expanded = YES;
}


@end
