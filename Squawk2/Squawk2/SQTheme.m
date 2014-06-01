//
//  SQTheme.m
//  Squawk2
//
//  Created by Nate Parrott on 3/5/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQTheme.h"
#import "NSURL+QueryParser.h"
#import <UIColor+HexString.h>

NSString * const SQThemeChangedNotification = @"SQThemeChangedNotification";

NSDictionary* SQThemeDict = nil;

@implementation SQTheme

+(void)setup {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:16]} forState:UIControlStateNormal];
    
    NSString* theme = [[NSUserDefaults standardUserDefaults] valueForKey:@"SQThemeURL"];
    if (!theme) {
        theme = @"squawk://theme?p=fa5235&r=fa8136&b=000000&c=ff3057&u=ffffff";
    }
    [self updateThemeFromURL:[NSURL URLWithString:theme]];
}

+(UIColor*)black {
    return [UIColor colorWithWhite:0.102 alpha:1.000];
}
+(UIColor*)yellow {
    return [UIColor colorWithRed:0.953 green:0.878 blue:0.004 alpha:1.000];
}
+(UIColor*)gray {
    return [UIColor colorWithWhite:0.204 alpha:1.000];
}
+(UIColor*)red {
    return [UIColor colorWithRed:1.000 green:0.189 blue:0.342 alpha:1.000];
}
+(UIColor*)blue {
    return [UIColor colorWithRed:0.192 green:0.439 blue:0.592 alpha:1.000];
    //return [UIColor colorWithRed:0.098 green:0.580 blue:0.984 alpha:1.000];
}
+(UIColor*)orange {
    return [UIColor colorWithRed:0.973 green:0.557 blue:0.302 alpha:1.000];
}
+(UIColor*)lightBlue {
    return [UIColor colorWithRed:0.416 green:0.722 blue:0.839 alpha:1.000];
}
+(UIColor*)lightGray {
    return [UIColor colorWithRed:0.753 green:0.755 blue:0.759 alpha:1.000];
}

+(UIColor*)rowColorForRecording {
    return SQThemeDict[@"r"];
    return [SQTheme orange];
}
+(UIColor*)rowColorForPlayback {
    return SQThemeDict[@"p"];
    return [UIColor colorWithRed:0.980 green:0.322 blue:0.208 alpha:1.000];
}
+(UIColor*)mainBackground {
    return SQThemeDict[@"b"];
    return [UIColor blackColor];
}
+(UIColor*)controlsTint {
    return SQThemeDict[@"c"];
    return [SQTheme red];
}
+(UIColor*)mainUITint {
    return SQThemeDict[@"u"];
    return [UIColor whiteColor];
}
+(void)updateThemeFromURL:(NSURL*)url {
    [[NSUserDefaults standardUserDefaults] setObject:url.absoluteString forKey:@"SQThemeURL"];
    
    NSDictionary* queryDict = url.queryDictionary;
    NSMutableDictionary* themeDict = [NSMutableDictionary new];
    for (NSString* key in queryDict) {
        themeDict[key] = [UIColor colorWithHexString:queryDict[key]];
    }
    BOOL isInitialSetup = SQThemeDict==nil;
    SQThemeDict = themeDict;
    if (!isInitialSetup) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SQThemeChangedNotification object:nil];
    }
}

@end
