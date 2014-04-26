//
//  WSFriendsOnSquawk.m
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSFriendsOnSquawk.h"
#import "NPContact.h"
#import "WSPersistentDictionary.h"
#import "WSAppDelegate.h"

@implementation WSFriendsOnSquawk

+(WSFriendsOnSquawk*)manager {
    WSFriendsOnSquawk* manager = [WSPersistentDictionary shared][@"WSFriendsOnSquawk"];
    if (!manager) {
        manager = [WSFriendsOnSquawk new];
        [WSPersistentDictionary shared][@"WSFriendsOnSquawk"] = manager;
    }
    return manager;
}
-(id)init {
    self = [super init];
    
    _phoneNumbersSignal = [RACReplaySubject replaySubjectWithCapacity:1];
    _phoneNumbersOnSquawk = [NSMutableSet new];
    _lookedUpPhoneNumbers = [NSMutableSet new];
    [_phoneNumbersSignal sendNext:nil];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    
    _phoneNumbersOnSquawk = [aDecoder decodeObjectForKey:@"phoneNumbersOnSquawk"];
    _lookedUpPhoneNumbers = [aDecoder decodeObjectForKey:@"lookedUpPhoneNumbers"];
    _lastRefresh = [aDecoder decodeObjectForKey:@"lastRefresh"];
    [_phoneNumbersSignal sendNext:_phoneNumbersOnSquawk];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_phoneNumbersOnSquawk forKey:@"phoneNumbersOnSquawk"];
    [aCoder encodeObject:_lookedUpPhoneNumbers forKey:@"lookedUpPhoneNumbers"];
    [aCoder encodeObject:_lastRefresh forKey:@"lastRefresh"];
}

-(RACSignal*)phoneNumbersOfFriendsOnSquawkSignal {
    return _phoneNumbersSignal;
}

-(NSSet*)phoneNumbersOfFriendsOnSquawk {
    return _phoneNumbersOnSquawk;
}

-(void)updateIfNecessaryUsingContactsList:(NSArray*)contacts {
    [self updateWithContacts:contacts];
}
-(void)updateWithContacts:(NSArray*)contacts {
    if (_refreshInProgress) return;
    int max = 80;
    NSArray* numbers = [[contacts.rac_sequence flattenMap:^RACStream *(NPContact* contact) {
        return [[contact phoneNumbers] rac_sequence];
    }] filter:^BOOL(id value) {
        return ![_lookedUpPhoneNumbers containsObject:value];
    }].array;
    if (numbers.count > max) {
        numbers = [numbers subarrayWithRange:NSMakeRange(0, max)];
    }
    
    if (numbers.count==0) {
        if ([NSDate timeIntervalSinceReferenceDate] - _lastRefresh.timeIntervalSinceReferenceDate > WSFriendsOnSquawkRefreshInterval) {
            [self checkForNewFriendsOnSquawk];
        }
    } else {
        _refreshInProgress = YES;
        [PFCloud callFunctionInBackground:@"updateUserContactsListing" withParameters:@{@"add": numbers} block:^(NSArray* friendsOnSquawk, NSError *error) {
            _refreshInProgress = NO;
            if (friendsOnSquawk) {
                [_phoneNumbersOnSquawk addObjectsFromArray:friendsOnSquawk];
                [_lookedUpPhoneNumbers addObjectsFromArray:numbers];
                [_phoneNumbersSignal sendNext:_phoneNumbersOnSquawk];
                
                [[WSPersistentDictionary shared] didUpdateValueForKey:@"WSFriendsOnSquawk"];
                
                [self updateWithContacts:contacts];
            }
        }];
    }
}
-(void)checkForNewFriendsOnSquawk {
    [PFCloud callFunctionInBackground:@"allFriendsOnSquawk" withParameters:@{} block:^(id nums, NSError *error) {
        if (nums) {
            [_phoneNumbersOnSquawk addObjectsFromArray:nums];
            _lastRefresh = [NSDate date];
            [[WSPersistentDictionary shared] didUpdateValueForKey:@"WSFriendsOnSquawk"];
        }
    }];
}
-(void)addKnownPhoneNumber:(NSString*)num {
    [_phoneNumbersOnSquawk addObject:num];
    [_phoneNumbersSignal sendNext:_phoneNumbersOnSquawk];
    [[WSPersistentDictionary shared] didUpdateValueForKey:@"WSFriendsOnSquawk"];
}

@end
