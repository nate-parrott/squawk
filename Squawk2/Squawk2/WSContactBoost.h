//
//  WSContactBoost.h
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

/*
 this class is used to 'boost' contacts in the contacts list.
 this allows us to put newly added contacts at the top of the list, even though they haven't been squawked yet.
 this also allows for users who've just been added to squawk to appear in the list when the user gets a notification that they've joined
 */

@interface WSContactBoost : NSObject

+(RACSignal*)updateSignal;
+(void)boostThreadWithPhoneNumbers:(NSArray*)phoneNumbers;
+(NSDate*)boostDateForThreadWithPhoneNumbers:(NSArray*)phoneNumbers;
+(NSArray*)identifiersForBoostedThreads;

+(void)boostPhoneNumber:(NSString*)phoneNumber;

@end
