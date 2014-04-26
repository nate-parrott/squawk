//
//  UIFont+OverrideSystemFont.m
//  Squawk2
//
//  Created by Nate Parrott on 3/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "UIFont+OverrideSystemFont.h"
#import <objc/runtime.h>

@implementation UIFont (OverrideSystemFont)

+(UIFont*)systemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"AvenirNext-Regular" size:fontSize];
}
+(UIFont*)boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:fontSize];
}
+(UIFont*)x_fontWithName:(NSString*)name size:(CGFloat)size {
    return [UIFont x_fontWithName:@"ChalkboardSE-Regular" size:size];
}
+(void)swizzleComicSans {
    /*Method original = class_getClassMethod([UIFont class], @selector(fontWithName:size:));
    Method replacement = class_getClassMethod([UIFont class], @selector(x_fontWithName:size:));
    method_exchangeImplementations(original, replacement);*/
}

@end
