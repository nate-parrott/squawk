//
//  NSData+HexDump.m
//  Squawk2
//
//  Created by Nate Parrott on 3/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSData+HexDump.h"

@implementation NSData (HexDump)

-(NSString*)asHexadecimal {
    NSData *data = self;
    NSUInteger dataLength = [data length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [data bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    return string;
}

@end
