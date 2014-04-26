//
//  WSFriendsOnSquawk.h
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

@interface WSFriendsOnSquawk : NSObject <NSCoding> {
    NSMutableSet* _phoneNumbersOnSquawk;
    NSMutableSet* _lookedUpPhoneNumbers;
    RACReplaySubject* _phoneNumbersSignal;
    NSDate* _lastRefresh;
    BOOL _refreshInProgress;
}

+(WSFriendsOnSquawk*)manager;

-(RACSignal*)phoneNumbersOfFriendsOnSquawkSignal; // signal of NSSet's
-(NSSet*)phoneNumbersOfFriendsOnSquawk;

-(void)updateIfNecessaryUsingContactsList:(NSArray*)contacts;

-(void)addKnownPhoneNumber:(NSString*)num;

@end
