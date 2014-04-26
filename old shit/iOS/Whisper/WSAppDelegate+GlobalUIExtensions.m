//
//  WSAppDelegate+GlobalUIExtensions.m
//  Squawk
//
//  Created by Nate Parrott on 2/13/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSAppDelegate+GlobalUIExtensions.h"
#import "WSToastNotificationView.h"

@implementation WSAppDelegate (GlobalUIExtensions)

-(void)toast:(NSString*)message {
    [WSToastNotificationView showToastMessage:message inView:self.window.rootViewController.view];
}
-(void)showCheckmarkAnimationStartingFromButton:(UIButton*)sourceButton {
    UIView* container = self.window.rootViewController.view;
    
    UIView* bg = [UIView new];
    bg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0];
    bg.frame = CGRectMake(0, 0, container.bounds.size.width, 70);
    [container addSubview:bg];
    
    UIView* border = [UIView new];
    border.backgroundColor = [UIColor colorWithRed:0.869 green:0.194 blue:0.190 alpha:1.000];
    border.frame = CGRectMake(0, bg.frame.size.height-2, bg.frame.size.width, 2);
    [bg addSubview:border];
    border.alpha = 0;
    
    UILabel* name = [UILabel new];
    name.textColor = [UIColor colorWithRed:0.969 green:0.294 blue:0.290 alpha:1.000];
    name.font = [UIFont boldSystemFontOfSize:17];
    name.text = [NSString stringWithFormat:@"%@: ", [self.currentUser valueForKey:@"nickname"]];
    CGSize nameSize = [name sizeThatFits:CGSizeMake(container.bounds.size.width-100, MAXFLOAT)];
    name.frame = CGRectMake(20, 30, nameSize.width, nameSize.height);
    name.transform = CGAffineTransformMakeTranslation(-(name.frame.origin.x+name.frame.size.width), 0);
    [bg addSubview:name];
    
    UIImageView* redCheck = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark2"]];
    redCheck.frame = [bg convertRect:sourceButton.bounds fromView:sourceButton];
    [bg addSubview:redCheck];
    
    __block CGPoint toPt;
    [UIView animateWithDuration:0.9 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        name.transform = CGAffineTransformIdentity;
        CGFloat checkSize = nameSize.height*1.3;
        redCheck.bounds = CGRectMake(0, 0, checkSize, checkSize);
        bg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
        border.alpha = 1;
        
        UIBezierPath* path = [UIBezierPath bezierPath];
        CGPoint fromPt = [bg convertPoint:sourceButton.center fromView:sourceButton.superview];
        toPt = CGPointMake(name.frame.origin.x+name.frame.size.width+checkSize, name.frame.origin.y+name.frame.size.height/2);
        CGPoint controlPt = CGPointMake(fromPt.x, toPt.y);
        [path moveToPoint:fromPt];
        [path addCurveToPoint:toPt controlPoint1:controlPt controlPoint2:controlPt];
        CAKeyframeAnimation* anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim.duration = 0.9;
        anim.removedOnCompletion = NO;
        anim.path = path.CGPath;
        anim.fillMode = kCAFillModeForwards;
        [redCheck.layer addAnimation:anim forKey:@"move"];
        
    } completion:^(BOOL finished) {
        [redCheck.layer removeAnimationForKey:@"move"];
        redCheck.center = toPt;
        [UIView animateWithDuration:0.4 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^{
            bg.frame = CGRectMake(0, -200, bg.frame.size.width, bg.frame.size.height);
        } completion:^(BOOL finished) {
            [bg removeFromSuperview];
        }];
    }];
    
}


@end
