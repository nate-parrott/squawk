//
//  NSString+TempFilePath.m
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSString+TempFilePath.h"

@implementation NSString (TempFilePath)

+(NSString*)tempFilePathWithExtension:(NSString*)ext {
    static NSInteger i = 0;
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.%@", (i++)%20, ext]];
}

@end
