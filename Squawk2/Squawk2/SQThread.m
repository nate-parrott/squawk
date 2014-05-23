//
//  SQThread.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQThread.h"
#import "NPContact.h"
#import "WSPersistentDictionary.h"
#import "SQAPI.h"
#import "WSPersistentDictionary.h"
#import "SQFriendsOnSquawk.h"
#import "WSContactBoost.h"
#import "SQSquawkCache.h"
#import "NSString+NormalizeForSearch.h"
#import "NPAddressBook.h"

NSString *const SQThreadUpdatedNotification = @"SQThreadUpdatedNotification";
NSString *const SQSquawkListenedStatusChangedNotification = @"SQSquawkListenedStatusChangedNotification";

@implementation SQThread

#pragma mark Thread creation
+(NSArray*)makeThreadsFromRecentSquawks:(NSArray*)squawks contacts:(NSArray*)contacts {
    // keys are all the phone numbers in a thread, including the current user, sorted and combined with ','
    NSMutableDictionary* threadsForIdentifiers = [NSMutableDictionary new];
    
    NSString* myNumber = [SQAPI currentPhone];
    if (!myNumber) {
        return @[];
    }
    
    for (NPContact* contact in contacts) {
        SQThread* thread = [SQThread new];
        [thread.contacts addObject:contact];
        for (NSString* num in contact.phoneNumbers) {
            if ([num isEqualToString:myNumber]) continue;
            threadsForIdentifiers[[self identifierForThreadWithPhoneNumbers:@[num, myNumber]]] = thread;
        }
    }
    
    for (NSDictionary* squawk in squawks) {
        NSMutableArray* numbers = [squawk[@"thread_members"] mutableCopy];
        NSString* identifier = [self identifierForThreadWithPhoneNumbers:numbers];
        SQThread* thread = threadsForIdentifiers[identifier];
        if (thread) {
            
        } else {
            thread = [SQThread new];
            [thread.phoneNumbers addObjectsFromArray:numbers];
            threadsForIdentifiers[identifier] = thread;
        }
        [thread.squawks addObject:[squawk mutableCopy]];
    }
    
    for (NSString* identifier_ in [WSContactBoost identifiersForBoostedThreads]) {
        NSString* identifier = identifier_;
        NSArray* phones = [self phoneNumbersFromIdentifier:identifier];
        if (![phones containsObject:[SQAPI currentPhone]]) {
            identifier = [self identifierForThreadWithPhoneNumbers:[phones arrayByAddingObject:[SQAPI currentPhone]]];
        }
        if (!threadsForIdentifiers[identifier]) {
            SQThread* thread = [SQThread new];
            [thread.phoneNumbers addObjectsFromArray:[self phoneNumbersFromIdentifier:identifier]];
            threadsForIdentifiers[identifier] = thread;
        }
    }
    
    // unique the threads:
    NSMutableArray* threads = [[[NSSet setWithArray:threadsForIdentifiers.allValues] allObjects] mutableCopy];
    
    for (SQThread* thread in threads) {
        // now if we've still got threads that exist only because the user has a contact, we'll want to manually populate the -phoneNumbers field:
        if (thread.contacts.count>0 && thread.phoneNumbers.count==0) {
            [thread.phoneNumbers addObject:[thread.contacts.firstObject mobileNumber]];
        }
    }
        
    return threads;
}
+(NSArray*)searchThreads:(NSArray*)threads withQuery:(NSString*)query {
    if (query.length) {
        query = [query normalizedForSearch];
        return [threads.rac_sequence filter:^BOOL(SQThread* thread) {
            return [thread.stringForSearching rangeOfString:query].location != NSNotFound;
        }].array;
    } else {
        return threads;
    }
}
+(NSArray*)sortThreadsIntoSections:(NSArray*)threads {
    if (!threads) {
        return @[];
    }
    
    int nRecent = 5;
    NSMutableArray* recent = [NSMutableArray new];
    NSTimeInterval recentCutoff = 0;
    for (SQThread* thread in threads) {
        _SQThreadComparisonData* compData = [thread compData];
        if (compData->_date > recentCutoff) {
            if (recent.count < nRecent) {
                [recent addObject:thread];
            } else {
                for (int i=0; i<recent.count; i++) {
                    _SQThreadComparisonData* existingEntryCompData = [recent[i] compData];
                    if (compData->_date > existingEntryCompData->_date) {
                        [recent replaceObjectAtIndex:i withObject:thread];
                        break;
                    }
                }
                recentCutoff = compData->_date;
                for (SQThread* recentThread in recent) {
                    recentCutoff = MIN(recentCutoff, [recentThread compData]->_date);
                }
            }
        }
    }
    
    NSMutableArray* onSquawk = [NSMutableArray new];
    NSMutableArray* notOnSquawk = [NSMutableArray new];
    for (SQThread* thread in threads) {
        if (![recent containsObject:thread]) {
            _SQThreadComparisonData* compData = [thread compData];
            if (compData->_registered) {
                [onSquawk addObject:thread];
            } else {
                [notOnSquawk addObject:thread];
            }
        }
    }
    
    NSComparisonResult (^compareByDate)(id obj1, id obj2) = ^(id obj1, id obj2) {
        return (NSComparisonResult)([obj2 compData]->_date -  [obj1 compData]->_date);
    };
    [recent sortUsingComparator:compareByDate];
    
    NSComparisonResult (^compareByName)(id obj1, id obj2) = ^(id obj1, id obj2) {
        return (NSComparisonResult)strcmp([obj1 compData]->_name, [obj2 compData]->_name);
    };
    [onSquawk sortUsingComparator:compareByName];
    [notOnSquawk sortUsingComparator:compareByName];
    
    return @[recent, onSquawk, notOnSquawk];
}
-(id)init {
    self = [super init];
    self.phoneNumbers = [NSMutableSet new];
    self.contacts = [NSMutableArray new];
    self.squawks = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updated:) name:SQSquawkListenedStatusChangedNotification object:nil];
    return self;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(NSArray*)numbersToDisplay {
    NSMutableArray* nums = self.phoneNumbers.allObjects.mutableCopy;
    if (nums.count > 1) {
        [nums removeObject:[SQAPI currentPhone]];
    }
    return nums;
}
#pragma mark Labels
-(NSString*)identifier {
    return [SQThread identifierForThreadWithPhoneNumbers:self.phoneNumbers.allObjects];
}
-(NSString*)displayName {
    NSArray* nums = self.numbersToDisplay;
    return [[nums.rac_sequence map:^id(id value) {
        return nums.count==1? [SQThread nameForNumber:value] : [SQThread shortNameForNumber:value];
    }].array componentsJoinedByString:@", "];
}
+(NSString*)shortNameForNumber:(NSString*)number {
    return [[self nameForNumber:number] componentsSeparatedByString:@" "].firstObject;
}
+(NSString*)nameForNumber:(NSString*)number {
    NSDictionary* specials = [self specialNames];
    if (specials[number]) {
        return specials[number];
    }
    return [[[NPAddressBook contactsByPhoneNumber].first objectForKey:number] displayLabel]? : number;
}
-(NSString*)veryShortName {
    NSArray* nameComponents = [self.displayName componentsSeparatedByString:@" "];
    NSString* firstName = nameComponents.firstObject;
    if (self.numbersToDisplay.count > 1) {
        firstName = @"them";
    } else {
        if ([firstName isEqualToString:@"Squawk"]) {
            firstName = nameComponents.lastObject;
            if ([firstName isEqualToString:@"Robot"]) {
                firstName = @"the robot";
            }
        }
    }
    return firstName;
}
#pragma mark Sorting
+(NSString*)identifierForThreadWithPhoneNumbers:(NSArray*)numbers {
    NSMutableArray* nums = numbers.mutableCopy;
    
    NSString* curPhone = [SQAPI currentPhone];
    if (curPhone && ![nums containsObject:curPhone]) {
        [nums addObject:curPhone];
    }
    
    int i = 0;
    for (NSString* num in numbers) {
        nums[i] = [NPContact normalizePhone:num];
        i++;
    }
    [nums sortUsingSelector:@selector(compare:)];
    NSString* identifier = [nums componentsJoinedByString:@","];
    return identifier;
}
+(NSArray*)phoneNumbersFromIdentifier:(NSString*)identifier {
    return [identifier componentsSeparatedByString:@","];
}
-(_SQThreadComparisonData*)compData {
    if (!_hasCompData) {
        _compData._date = [self dateForSorting];
        
        const char* name = [self displayName].UTF8String;
        size_t len = strlen(name);
        _compData._name = malloc(len);
        memcpy(_compData._name, name, len);
        
        _compData._registered = [self membersAreRegistered];
        
        _compData._hash = [self hash];
        
        _hasCompData = YES;
    }
    return &_compData;
}
- (NSComparisonResult)compare:(id)other {
    _SQThreadComparisonData* selfData = [self compData];
    _SQThreadComparisonData* otherData = [other compData];
    
    NSComparisonResult date = otherData->_date - selfData->_date;
    if (date) return date;
    NSComparisonResult signup = otherData->_registered - selfData->_registered;
    if (signup) return signup;
    NSComparisonResult name = strcmp(selfData->_name, otherData->_name);
    if (name) return name;
    return selfData->_hash - otherData->_hash;
};
-(NSTimeInterval)dateForSorting {
    NSTimeInterval time = 0;
    
    NSTimeInterval boostTime = [[WSContactBoost boostDateForThreadWithPhoneNumbers:self.phoneNumbers.allObjects] timeIntervalSinceReferenceDate];
    time = MAX(time, boostTime);
    
    NSNumber* timestamp =  [self.squawks.firstObject objectForKey:@"date"];
    if (timestamp) {
        NSTimeInterval converted = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue].timeIntervalSinceReferenceDate;
        time = MAX(time, converted);
    }
    return time;
}
-(BOOL)membersAreRegistered {
    if (self.squawks.count > 0) {
        return YES;
    }
    NSSet* set = [[[SQFriendsOnSquawk shared] setOfPhoneNumbersOfFriendsOnSquawk] first];
    for (NSString* num in self.phoneNumbers) {
        if ([set containsObject:num]) {
            return YES;
        }
    }
    return NO;
}
#pragma mark Squawks
-(void)updated:(NSNotification*)notif {
    NSString* squawkID = notif.object;
    for (NSDictionary* squawk in _squawks) {
        if ([squawk[@"_id"] isEqualToString:squawkID]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SQThreadUpdatedNotification object:self];
        }
    }
}
-(NSArray*)unread {
    return [self.squawks.rac_sequence filter:^BOOL(NSMutableDictionary* value) {
        return ![SQThread isSquawkListened:value];
    }].array;
}
+(void)listenedToSquawk:(NSMutableDictionary *)squawk {
    squawk[@"listened"] = @YES;
    if (![WSPersistentDictionary shared][@"ListenedSquawkIDs"]) {
        [WSPersistentDictionary shared][@"ListenedSquawkIDs"] = [NSMutableSet new];
    }
    [[WSPersistentDictionary shared][@"ListenedSquawkIDs"] addObject:squawk[@"_id"]];
    [[WSPersistentDictionary shared] didUpdateValueForKey:@"ListenedSquawkIDs"];
    
    [self notifyServerUserListenedToSquawk:squawk];
    [[NSNotificationCenter defaultCenter] postNotificationName:SQSquawkListenedStatusChangedNotification object:squawk[@"_id"] userInfo:nil];
    [SQSquawkCache dataUpdated];
    [UIApplication sharedApplication].applicationIconBadgeNumber = MAX(0, [UIApplication sharedApplication].applicationIconBadgeNumber-1);
    
    [[SQSquawkCache shared] deleteCachesForSquawkWithID:squawk[@"_id"]];
}
+(void)notifyServerUserListenedToSquawk:(NSDictionary*)squawk {
    [SQAPI post:@"/squawks/listened" args:@{@"id": squawk[@"_id"]} data:nil callback:^(NSDictionary *result, NSError *error) {
    }];
}
+(BOOL)isSquawkListened:(NSMutableDictionary*)squawk {
    return [squawk[@"listened"] boolValue] || [[WSPersistentDictionary shared][@"ListenedSquawkIDs"] containsObject:squawk[@"_id"]];
}
+(void)makeSureListenedSquawksAreKnownOnServer:(NSArray*)squawksFromServer {
    NSMutableSet* localCacheOfListenedSquawkIDs = [WSPersistentDictionary shared][@"ListenedSquawkIDs"];
    for (NSDictionary* squawk in squawksFromServer) {
        if ([squawk[@"listened"] boolValue]==NO && [localCacheOfListenedSquawkIDs containsObject:squawk[@"_id"]]) {
            [self notifyServerUserListenedToSquawk:squawk];
        }
    }
}
+(void)deleteSquawks:(NSArray*)squawks intervalBetweenEach:(NSTimeInterval)delay {
    if (squawks.firstObject) {
        [self listenedToSquawk:squawks.firstObject];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self deleteSquawks:[squawks subarrayWithRange:NSMakeRange(1, squawks.count-1)] intervalBetweenEach:delay];
        });
    }
}
+(NSDictionary*)specialNames {
    return @{@"00000000000": NSLocalizedString(@"Squawk Robot", @""), @"00000000001": NSLocalizedString(@"Squawk Feedback", @"")};
}
#pragma mark Search
-(NSString*)stringForSearching {
    if (!_stringForSearching) {
        _stringForSearching = [[self displayName] normalizedForSearch];
    }
    return _stringForSearching;
}

@end
