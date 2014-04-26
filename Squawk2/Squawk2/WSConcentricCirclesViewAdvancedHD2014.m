//
//  WSConcentricCirclesViewAdvancedHD2014.m
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSConcentricCirclesViewAdvancedHD2014.h"

#define UPDATE_INTERVAL 0.3

@implementation WSConcentricCirclesViewAdvancedHD2014

-(void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self setup];
}
-(void)setup {
    if (_speedMultiplier==0) _speedMultiplier = 1;
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateAnimated) userInfo:nil repeats:YES];
        _prevUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    }
    if (!_views) {
        _views = [NSMutableArray new];
        NSArray* colors = @[
                            [UIColor colorWithRed:0.976 green:0.843 blue:0.404 alpha:1.000],
                            
                            [UIColor colorWithRed:0.973 green:0.794 blue:0.365 alpha:1.000],
                            [UIColor colorWithRed:0.973 green:0.694 blue:0.325 alpha:1.000],
                            [UIColor colorWithRed:0.973 green:0.607 blue:0.312 alpha:1.000],
                            [UIColor colorWithRed:0.973 green:0.557 blue:0.302 alpha:1.000],
                            
                            [UIColor colorWithRed:0.973 green:0.607 blue:0.312 alpha:1.000],
                            [UIColor colorWithRed:0.973 green:0.694 blue:0.325 alpha:1.000],
                            [UIColor colorWithRed:0.973 green:0.794 blue:0.365 alpha:1.000]
                            ];
        for (UIColor* color in colors) {
            UIView* view = [UIView new];
            view.frame = CGRectMake(0, 0, 2, 2);
            view.layer.cornerRadius = 1;
            view.backgroundColor = color;
            [self insertSubview:view atIndex:0];
            [_views addObject:view];
        }
        [self update];
    }
}
-(void)removeFromSuperview {
    [_timer invalidate];
    _timer = nil;
    [super removeFromSuperview];
}
-(void)updateAnimated {
    [UIView animateWithDuration:UPDATE_INTERVAL delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [self update];
    } completion:^(BOOL finished) {
        
    }];
}
-(void)update {
    [self setup];
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval dt = now - _prevUpdateTime;
    dt *= _speedMultiplier * 0.7;
    _elapsed += dt;
    NSTimeInterval t = _elapsed;
    NSTimeInterval prevT = t - dt;
    _prevUpdateTime = now;
    CGFloat maxScale = sqrtf(powf(self.bounds.size.width, 2) + powf(self.bounds.size.height, 2)) * 1.8;
    
    for (int i=0; i<_views.count; i++) {
        UIView* view = _views[i];
        view.hidden = t+i*1.0/(_views.count-1) < 1;
        CGFloat scale = fmodf(t+i*1.0/(_views.count-1), 1);
        CGFloat prevScale = fmodf(prevT+i*1.0/(_views.count-1), 1);
        if (scale < prevScale) {
            [view removeFromSuperview];
            [self addSubview:view];
            view.transform = CGAffineTransformMakeScale(0.001, 0.001);
        }
        view.transform = CGAffineTransformMakeScale(scale*maxScale, scale*maxScale);
        view.center = _centerPoint;
    }
}

@end
