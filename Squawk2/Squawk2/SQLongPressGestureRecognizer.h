//
//  SQLongPressGestureRecognizer.h
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQLongPressGestureRecognizer : UILongPressGestureRecognizer {
    NSTimeInterval _touchDownTime;
    CGPoint _startPoint;
}

@property NSTimeInterval durationBeforeTouchLock;

@end
