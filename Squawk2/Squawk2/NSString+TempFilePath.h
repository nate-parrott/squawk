//
//  NSString+TempFilePath.h
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TempFilePath)

+(NSString*)tempFilePathWithExtension:(NSString*)ext;

@end
