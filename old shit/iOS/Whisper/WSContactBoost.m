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

NSString* WSBoostedContacts = @"WSBoostedContacts";

@implementation WSContactBoost

+(RACSignal*)updateSignal {
    return [[WSPersistentDictionary shared] signalForKey:WSBoostedContacts];
}
+(NSDictionary*)boostDatesForPhoneNumbers {
    return [WSPersistentDictionary shared][WSBoostedContacts];
}
+(void)boostPhoneNumber:(NSString*)phoneNumber {
    phoneNumber = [NPContact normalizePhone:phoneNumber];
    
    NSMutableDictionary* boosted = [WSPersistentDictionary shared][WSBoostedContacts];
    if (!boosted) {
        boosted = [NSMutableDictionary new];
        boosted[phoneNumber] = [NSDate date];
        [WSPersistentDictionary shared][WSBoostedContacts] = boosted;
    } else {
        boosted[phoneNumber] = [NSDate date];
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

@end
