//
//  SQTheme.h
//  Squawk2
//
//  Created by Nate Parrott on 3/5/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const SQThemeChangedNotification;

@interface SQTheme : NSObject

+(void)apply;

+(UIColor*)black;
+(UIColor*)yellow;
+(UIColor*)gray;
+(UIColor*)red;
+(UIColor*)blue;
+(UIColor*)orange;
+(UIColor*)lightBlue;
+(UIColor*)lightGray;

+(UIColor*)rowColorForPlayback;
+(UIColor*)rowColorForRecording;
+(UIColor*)mainBackground;
+(UIColor*)controlsTint;
+(UIColor*)mainUITint;

@end
