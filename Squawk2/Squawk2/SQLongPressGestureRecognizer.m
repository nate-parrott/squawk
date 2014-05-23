//
//  SQLongPressGestureRecognizer.m
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQLongPressGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface SQLongPressGestureRecognizer () {
    NSTimer* _scrollViewCancelTimer;
}

@end

@implementation SQLongPressGestureRecognizer

-(void)setState:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateBegan) {
        _scrollViewCancelTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeUntilCancellingScrolling target:self selector:@selector(cancelContainingScrollViews) userInfo:nil repeats:NO];
    } else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateFailed) {
        [_scrollViewCancelTimer invalidate];
    }
    [super setState:state];
}
-(void)cancelContainingScrollViews {
    _scrollViewCancelTimer = nil;
    
    UIView* view = self.view;
    while (view) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (id)view;
            if (scrollView.panGestureRecognizer.enabled) {
                scrollView.panGestureRecognizer.enabled = NO; // this cancels it
                scrollView.panGestureRecognizer.enabled = YES;
            }
        }
        view = view.superview;
    }
}

@end
