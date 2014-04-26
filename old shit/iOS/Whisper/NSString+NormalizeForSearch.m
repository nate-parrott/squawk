//
//  NSString+NormalizeForSearch.m
//  Squawk
//
//  Created by Nate Parrott on 1/31/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSString+NormalizeForSearch.h"

@implementation NSString (NormalizeForSearch)

-(NSString*)normalizedForSearch {
    NSMutableString* s = [NSMutableString stringWithString:self];
    CFRange range = CFRangeMake(0, s.length);
    CFStringTransform((CFMutableStringRef)s, &range, kCFStringTransformStripCombiningMarks, NO);
    return s.lowercaseString;
}

@end
