//
//  TBPulsingView.m
//  BigTicket
//
//  Created by Nate Parrott on 4/4/14.
//  Copyright (c) 2014 TB. All rights reserved.
//

#import "TBPulsingView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TBPulsingView

-(void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![self.layer animationForKey:@"Pulse"]) {
            CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
            pulse.fromValue = @1;
            pulse.toValue = @0.4;
            pulse.duration = 0.5;
            pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pulse.repeatCount = HUGE_VALF;
            pulse.autoreverses = YES;
            [self.layer addAnimation:pulse forKey:@"Pulse"];
        }
    });
}

@end
