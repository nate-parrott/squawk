//
//  SQCheckmarkSegment.m
//  Squawk2
//
//  Created by Nate Parrott on 4/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQCheckmarkSegment.h"

@implementation SQCheckmarkSegment

-(id)init {
    self = [super init];
    self.lightCheck = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-light"]];
    self.darkCheck = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-dark"]];
    [self.lightCheck sizeToFit];
    [self.darkCheck sizeToFit];
    [self addSubview:self.lightCheck];
    [self addSubview:self.darkCheck];
    [self resetAfterAnimation];
    self.label.textAlignment = NSTextAlignmentLeft;
    return self;
}
-(void)setPullProgress:(CGFloat)pullProgress {
    _pullProgress = pullProgress;
    if (pullProgress==0 && self.waitingForReset && !self.animationInProgress) {
        [self resetAfterAnimation];
    }
    [self setNeedsLayout];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectMake(20, 0, 80, self.bounds.size.height);
    self.lightCheck.center = self.darkCheck.center = CGPointMake(13, self.bounds.size.height/2 - _pullProgress*20);
    self.darkCheck.alpha = _pullProgress;
    self.lightCheck.alpha = 1-_pullProgress;
    if (self.waitingForReset || self.animationInProgress) {
        self.lightCheck.alpha = self.darkCheck.alpha = 0;
    }
    self.darkCheck.transform = CGAffineTransformMakeScale(1+_pullProgress, 1+_pullProgress);
}
-(void)animateSendingCheckmark:(void(^)())completion {
    self.label.text = NSLocalizedString(@"Sent", @"").lowercaseString;
    
    self.animationInProgress = self.waitingForReset = YES;
    
    UIView* snapshot = [_darkCheck snapshotViewAfterScreenUpdates:NO];
    _darkCheck.alpha = 0;
    UIView* rootView = AppDelegate.window.rootViewController.view;
    [rootView addSubview:snapshot];
    NSTimeInterval duration = 0.6;
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGPoint fromPt = [rootView convertPoint:_darkCheck.center fromView:_darkCheck.superview];
    CGPoint toPt = [rootView convertPoint:CGPointMake(self.window.rootViewController.view.frame.size.width+_darkCheck.frame.size.width, -_darkCheck.frame.size.height) fromView:self.window.rootViewController.view];
    CGPoint controlPt = CGPointMake(fromPt.x, toPt.y-30);
    [path moveToPoint:fromPt];
    [path addCurveToPoint:toPt controlPoint1:controlPt controlPoint2:controlPt];
    CAKeyframeAnimation* anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.path = path.CGPath;
    anim.fillMode = kCAFillModeForwards;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [snapshot.layer addAnimation:anim forKey:@"move"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.animationInProgress = NO;
        self.pullProgress = self.pullProgress;
        [snapshot.layer removeAnimationForKey:@"move"];
        [snapshot removeFromSuperview];
        completion();
    });
}
-(void)resetAfterAnimation {
    self.waitingForReset = NO;
    self.pullProgress = 0;
    self.label.text = NSLocalizedString(@"Pull to send checkmark", @"").lowercaseString;
}

@end
