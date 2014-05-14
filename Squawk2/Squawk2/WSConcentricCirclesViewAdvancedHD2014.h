//
//  WSConcentricCirclesViewAdvancedHD2014.h
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WSConcentricCirclesViewAdvancedHD2014;

const CGFloat WSConcentricCirclesViewAdvancedHD2014Hidden ;

@protocol WSConcentricCirclesViewAdvancedHD2014Delegate <NSObject>

-(CGFloat)concentricCirclesViewSpeed:(WSConcentricCirclesViewAdvancedHD2014*)view;

@end


@interface WSConcentricCirclesViewAdvancedHD2014 : UIView {
    NSTimer* _timer;
    NSMutableArray* _views;
    NSTimeInterval _elapsed;
    NSTimeInterval _prevUpdateTime;
}

@property CGPoint centerPoint;

-(void)update;

@property(weak)id<WSConcentricCirclesViewAdvancedHD2014Delegate> delegate;

@end
