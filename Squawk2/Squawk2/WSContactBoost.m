//
//  WSContactBoost.m
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSContactBoost.h"
#import "NPContact.h"
#import "WSPersistentDictionary.h"
#import "SQThread.h"

NSString* WSBoostedContacts = @"WSBoostedContacts";

@implementation WSContactBoost

+(RACSignal*)updateSignal {
    return [[WSPersistentDictionary shared] signalForKey:WSBoostedContacts];
}
+(NSDictionary*)boostDatesForThreadIdentifiers {
    return [WSPersistentDictionary shared][WSBoostedContacts];
}
+(void)boostPhoneNumber:(NSString*)phoneNumber {
    [self boostThreadWithPhoneNumbers:@[phoneNumber]];
}
+(void)boostThreadWithPhoneNumbers:(NSArray*)phoneNumbers {
    NSString* identifier = [SQThread identifierForThreadWithPhoneNumbers:phoneNumbers];
    
    NSMutableDictionary* boosted = [WSPersistentDictionary shared][WSBoostedContacts];
    if (!boosted) {
        boosted = [NSMutableDictionary new];
        boosted[identifier] = [NSDate date];
        [WSPersistentDictionary shared][WSBoostedContacts] = boosted;
    } else {
        boosted[identifier] = [NSDate date];
        while (boosted.count > 10) {
            NSString* oldestKey = nil;
            for (NSString* key in boosted) {
                if (oldestKey==nil || [boosted[key] timeIntervalSinceReferenceDate] < [boosted[oldestKey] timeIntervalSinceReferenceDate]) {
                    oldestKey = key;
                }
            }
            [boosted removeObjectForKey:oldestKey];
        }
        [[WSPersistentDictionary shared] didUpdateValueForKey:WSBoostedContacts];
    }
}

+(NSDate*)boostDateForThreadWithPhoneNumbers:(NSArray*)phoneNumbers {
    return [self boostDatesForThreadIdentifiers][[SQThread identifierForThreadWithPhoneNumbers:phoneNumbers]];
}
+(NSArray*)identifiersForBoostedThreads {
    return [self boostDatesForThreadIdentifiers].allKeys;
}

@end
