//
//  SQLongPressGestureRecognizer.m
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQLongPressGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation SQLongPressGestureRecognizer

-(void)reset {
    [super reset];
    _touchDownTime = 0;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_touchDownTime) {
        _touchDownTime = [NSDate timeIntervalSinceReferenceDate];
        _startPoint = [[touches anyObject] locationInView:self.view];
    }
    [super touchesBegan:touches withEvent:event];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.state == UIGestureRecognizerStateChanged && [NSDate timeIntervalSinceReferenceDate]-_touchDownTime < self.durationBeforeTouchLock) {
        CGPoint current = [[touches anyObject] locationInView:self.view];
        CGFloat distance = sqrtf(powf(_startPoint.x-current.x, 2) + powf(_startPoint.y-current.y, 2));
        if (distance > self.allowableMovement) {
            [self setState:UIGestureRecognizerStateFailed];
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

@end
