//
//  NSString+RandomString.m
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSString+RandomString.h"
#import <Security/Security.h>

@implementation NSString (RandomString)

+(NSString*)randomStringOfLength:(int)length insertDashes:(BOOL)dashes {
    int* randInts = malloc(sizeof(int)*length);
    SecRandomCopyBytes(kSecRandomDefault, sizeof(int)*length, (void*)randInts);
    NSString* pickChars = [NSString stringWithFormat:@"abcdefghijklmnopqrstuvwxyz0123456789"];
    NSMutableString* string = [NSMutableString new];
    for (int i=0; i<length; i++) {
        NSString* c = [pickChars substringWithRange:NSMakeRange(randInts[i]%pickChars.length, 1)];
        [string appendString:c];
        if (i+1 < length && dashes && (i+1)%4==0) {
            [string appendString:@"-"];
        }
    }
    free(randInts);
    return string;
}

@end
