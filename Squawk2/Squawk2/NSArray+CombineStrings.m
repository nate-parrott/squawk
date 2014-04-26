//
//  NSArray+CombineStrings.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSArray+CombineStrings.h"

@implementation NSArray (CombineStrings)

-(NSString*)combineStringsAsNaturalLanguage {
    if (self.count == 0) {
        return @"";
    } else if (self.count == 1) {
        return self.firstObject;
    } else {
        NSArray* allButLast = [self subarrayWithRange:NSMakeRange(0, self.count-1)];
        return [NSString stringWithFormat:@"%@ and %@", [allButLast componentsJoinedByString:@", "], self.lastObject];
    }
}

@end
