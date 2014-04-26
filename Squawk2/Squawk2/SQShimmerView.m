//
//  SQShimmerView.m
//  Squawk2
//
//  Created by Nate Parrott on 3/6/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQShimmerView.h"

const NSTimeInterval SQShimmerDuration = 0.6;
const NSTimeInterval SQShimmerGap = 0.1;
const CGFloat SQShimmerWidth = 180;

@implementation SQShimmerView

-(void)setShimmering:(BOOL)shimmering {
    if (_shimmering == shimmering) return;
    _shimmering = shimmering;
    if (_shimmering) {
        _shimmerTimer = [NSTimer scheduledTimerWithTimeInterval:SQShimmerDuration+SQShimmerGap target:self selector:@selector(singleShimmer) userInfo:nil repeats:YES];
    } else {
        [_shimmerTimer invalidate];
    }
}
-(void)singleShimmer {
    UIImageView* shimmerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shimmer"]];
    shimmerView.frame = CGRectMake(-SQShimmerWidth, 0, SQShimmerWidth, self.bounds.size.height);
    shimmerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    shimmerView.alpha = 0.5;
    [self addSubview:shimmerView];
    [UIView animateWithDuration:SQShimmerDuration animations:^{
        shimmerView.frame = CGRectMake(self.bounds.size.width+SQShimmerWidth, 0, SQShimmerWidth, self.bounds.size.height);
    } completion:^(BOOL finished) {
        [shimmerView removeFromSuperview];
    }];
}

@end
