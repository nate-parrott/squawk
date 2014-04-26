//
//  NSDate+MonotonicTime.h
//  Squawk
//
//  Created by Nate Parrott on 2/20/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (MonotonicTime)

+(long double)monotonicTime; // in seconds

@end
