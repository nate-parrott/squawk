//
//  SQAnimatedBird.m
//  Scratch3
//
//  Created by Nate Parrott on 5/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAnimatedBird.h"

@interface SQAnimatedBird () {
    UIImageView *_body, *_wing1, *_wing2;
    CADisplayLink* _displayLink;
    
    NSTimeInterval _time;
    
    UIView* _content;
}

@end

@implementation SQAnimatedBird

-(void)awakeFromNib {
    [super awakeFromNib];
    _content = [UIView new];
    [self addSubview:_content];
    _body = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"parrot-body"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _wing1 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"parrot-wing"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    //_wing2 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"parrot-wing"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [_content addSubview:_body];
    [_content addSubview:_wing1];
    [_content addSubview:_wing2];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat flap1 = (sin(_time-M_PI/2)+1)/2;
    CGFloat flap2 = (sin(_time+M_PI*0.2)+1)/2;
    
    if (flap1 < 0.05 && !_animating) {
        [_displayLink invalidate];
        _displayLink = nil;
        flap1 = 0;
    }
    
    _content.bounds = self.bounds;
    _content.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat k = 1;//self.animating? 1 : 0;
    CGFloat rise = (sin(_time+M_PI*0.5)+1) * k;
    _content.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(self.bounds.size.height*rise*0.02, self.bounds.size.height*rise*0.05), M_PI*2*0.08*k);
    
    CGFloat scale = self.bounds.size.height / [_body.image size].height;
    [_body sizeToFit];
    [_wing1 sizeToFit];
    [_wing2 sizeToFit];
    _body.transform = CGAffineTransformMakeScale(scale, scale);
    _body.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _wing1.transform = CGAffineTransformMakeScale(scale*1*(1-flap1) + -scale*1.2*flap1, scale);
    _wing2.transform = CGAffineTransformMakeScale(scale*1*(1-flap2) + -scale*1.2*flap2, scale);
    
    CGPoint center1 = CGPointMake(self.bounds.size.width*0.468, self.bounds.size.height*0.52);
    CGPoint center2 = CGPointMake(self.bounds.size.width*0.58, self.bounds.size.height*0.52);
    _wing1.center = CGPointMake(center1.x*(1-flap1) + center2.x*flap1, center1.y*(1-flap1) + center2.y*flap1);
    _wing2.center = CGPointMake(center1.x*(1-flap2) + center2.x*flap2, center1.y*(1-flap2) + center2.y*flap2);
}
-(void)displayLink {
    _time += [_displayLink duration] * 7;
    [self setNeedsLayout];
    [self layoutSubviews];
}
-(void)setAnimating:(BOOL)animating {
    if (animating==_animating) return;
    _animating = animating;
    if (animating) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLink)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}
-(void)dealloc {
    [_displayLink invalidate];
}

@end
