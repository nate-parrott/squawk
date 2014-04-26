//
//  NSDate+MonotonicTime.m
//  Squawk
//
//  Created by Nate Parrott on 2/20/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSDate+MonotonicTime.h"
#import <mach/mach.h>

@implementation NSDate (MonotonicTime)

+(long double)monotonicTime {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1;
    uint64_t time = mach_absolute_time();
    uint64_t nanoseconds = time * info.numer / info.denom;
    return nanoseconds / (long double)NSEC_PER_SEC;
}

@end
