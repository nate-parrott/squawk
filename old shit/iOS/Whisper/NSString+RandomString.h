//
//  NSString+RandomString.h
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RandomString)

+(NSString*)randomStringOfLength:(int)length insertDashes:(BOOL)dashes;

@end
