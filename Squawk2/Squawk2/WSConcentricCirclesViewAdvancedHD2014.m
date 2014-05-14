//
//  WSConcentricCirclesViewAdvancedHD2014.m
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSConcentricCirclesViewAdvancedHD2014.h"

#define UPDATE_INTERVAL 0.3

const CGFloat WSConcentricCirclesViewAdvancedHD2014Hidden = -1;

const int WSConcentricCirclesViewAdvancedHD2014NumColors = 19;

@implementation WSConcentricCirclesViewAdvancedHD2014

-(void)tintColorDidChange {
    [self updateColors];
}
-(void)updateColors {
    CGFloat hue;
    [[self tintColor] getHue:&hue saturation:NULL brightness:NULL alpha:NULL];
    for (int i=0; i<_views.count; i++) {
        CGFloat brightness = MIN(i, _views.count-i)*2.0/_views.count;
        [_views[i] setBackgroundColor:[UIColor colorWithHue:hue saturation:0.5+brightness*0.3 brightness:brightness*0.6+0.4 alpha:1]];
    }
}
-(void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self setup];
}
-(void)setup {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateAnimated) userInfo:nil repeats:YES];
        _prevUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    }
    if (!_views) {
        _views = [NSMutableArray new];
        for (int i=0; i<WSConcentricCirclesViewAdvancedHD2014NumColors; i++) {
            UIView* view = [UIView new];
            view.frame = CGRectMake(0, 0, 2, 2);
            view.layer.cornerRadius = 1;
            [self insertSubview:view atIndex:0];
            [_views addObject:view];
        }
        [self updateColors];
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
    
    for (UIView* v in _views) {
        v.center = _centerPoint;
    }
    
    CGFloat speed = [self.delegate concentricCirclesViewSpeed:self];
    if (speed==WSConcentricCirclesViewAdvancedHD2014Hidden && _elapsed!=0) {
        _elapsed = 0;
        [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            for (UIView* v in _views) {
                v.transform = CGAffineTransformMakeScale(0.001, 0.001);
            }
        } completion:^(BOOL finished) {
            
        }];
        return;
    }
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval dt = now - _prevUpdateTime;
    dt *= speed * 0.7;
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
    }
}


@end
