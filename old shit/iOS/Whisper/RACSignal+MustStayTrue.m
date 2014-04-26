//
//  RACSignal+MustStayTrue.m
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "RACSignal+MustStayTrue.h"
#import "NSDate+MonotonicTime.h"

@implementation RACSignal (MustStayTrue)

-(RACSignal*)mustStayTrueFor:(NSTimeInterval)duration {
    RACSubject* sub = [RACSubject subject];
    __block long double lastFalse = [NSDate monotonicTime];
    [self subscribeNext:^(id x) {
        if ([x boolValue]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (([NSDate monotonicTime] - lastFalse) >= duration) {
                    [sub sendNext:@YES];
                }
            });
        } else {
            lastFalse = [NSDate monotonicTime];
            [sub sendNext:@NO];
        }
    } error:^(NSError *error) {
        [sub sendError:error];
    } completed:^{
        [sub sendCompleted];
    }];
    return sub;
}

@end
