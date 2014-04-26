//
//  RACSignal+MapLatest.m
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "RACSignal+MapLatest.h"
#import <ReactiveCocoa.h>

@implementation RACSignal (MapLatest)

-(RACSignal*)mapLatest:(id(^)(id value))block {
    __block BOOL working = NO;
    __block BOOL hasNewValue = NO;
    __block id newValue;
    __block NSLock* lock = [NSLock new];
    RACSubject* sub = [RACSubject subject];
    [self subscribeNext:^(id x) {
        [lock lock];
        if (working) {
            hasNewValue = YES;
            newValue = x;
            [lock unlock];
        } else {
            working = YES;
            [lock unlock];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                while (1) {
                    [lock lock];
                    if (hasNewValue) {
                        hasNewValue = NO;
                        id val = newValue;
                        [lock unlock];
                        id result = block(val);
                        [sub sendNext:result];
                    } else {
                        working = NO;
                        [lock unlock];
                        break;
                    }
                }
            });
        }
    } error:^(NSError *error) {
        [sub sendError:error];
    } completed:^{
        [sub sendCompleted];
    }];
    return sub;
}

@end
