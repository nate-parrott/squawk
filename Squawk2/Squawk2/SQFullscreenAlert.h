//
//  SQFullscreenAlert.h
//  Scratch3
//
//  Created by Nate Parrott on 5/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQFullscreenAlert : UIView

@property(strong)UIColor *blackoutColor, *contentColor;
@property(strong)UIFont* font;
@property CGSize contentSize;

-(void)setImage:(UIImage*)image text:(NSString*)text;
-(void)presentQuick:(BOOL)quickIn andDismissAfter:(NSTimeInterval)displayDuration;

@end
