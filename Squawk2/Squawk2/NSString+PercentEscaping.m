//
//  NSString+PercentEscaping.m
//  Squawk2
//
//  Created by Nate Parrott on 3/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSString+PercentEscaping.h"

@implementation NSString (PercentEscaping)

-(NSString*)percentEscaped {
    CFStringRef safeString = CFURLCreateStringByAddingPercentEscapes (
                                                                      NULL,
                                                                      (CFStringRef)self,
                                                                      NULL,
                                                                      CFSTR("/%&=?$#+-~@<>|\\*,.()[]{}^!"),
                                                                      kCFStringEncodingUTF8
                                                                      );
    return CFBridgingRelease(safeString);
}

@end
