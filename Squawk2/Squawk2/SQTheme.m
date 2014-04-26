//
//  SQTheme.m
//  Squawk2
//
//  Created by Nate Parrott on 3/5/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQTheme.h"

@implementation SQTheme

+(void)apply {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:16]} forState:UIControlStateNormal];
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
    return [UIColor colorWithRed:0.843 green:0.855 blue:0.859 alpha:1.000];
}

@end
