//
//  SQDopplerView.m
//  SQScratch
//
//  Created by Nate Parrott on 3/14/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

@import QuartzCore;

#import "SQDopplerView.h"

@interface SQDopplerView () {
    NSMutableArray* _views;
    double _time;
    CADisplayLink* _displayLink;
}

@end


@implementation SQDopplerView

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setAnimating:YES];
}
-(void)setAnimating:(BOOL)animating {
    if (animating==_animating) return;
    _animating = animating;
    if (_numViews==0) _numViews = 4;
    if (_outgoingSpeed==0) _outgoingSpeed = 0.5;
    if (!_views) {
        _views = [NSMutableArray new];
        for (int i=0; i<_numViews; i++) {
            UIView* view = [UIView new];
            [self addSubview:view];
            view.layer.borderColor = [UIColor blackColor].CGColor;
            view.layer.borderWidth = 1;
            view.backgroundColor = [UIColor clearColor];
            [_views addObject:view];
        }
    }
    if (animating) {
        if (!_displayLink) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(animate:)];
        }
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}
-(void)animate:(CADisplayLink*)link {
    _time += link.duration * _outgoingSpeed;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    for (int i=0; i<_views.count; i++) {
        CGFloat size = fmodf(i*1.0/_views.count + _time, 1);
        if (size < 0) size += 1;
        UIView* view = _views[i];
        view.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        view.bounds = CGRectMake(0, 0, self.bounds.size.width*size, self.bounds.size.height*size);
        CGFloat fadeCutoff = 1;
        view.alpha = size>(1-fadeCutoff)? 1-(size-(1-fadeCutoff))/fadeCutoff : 1;
        /*if (size*self.bounds.size.width < view.layer.borderWidth*2) {
            view.alpha = size*self.bounds.size.width / view.layer.borderWidth*2;
        }*/
        view.layer.cornerRadius = (view.bounds.size.width + view.bounds.size.height)/4;
    }
}

@end
