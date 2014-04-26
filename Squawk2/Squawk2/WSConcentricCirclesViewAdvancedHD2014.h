//
//  WSConcentricCirclesViewAdvancedHD2014.h
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

//nate is a prick
@interface WSConcentricCirclesViewAdvancedHD2014 : UIView {
    NSTimer* _timer;
    NSMutableArray* _views;
    NSTimeInterval _elapsed;
    NSTimeInterval _prevUpdateTime;
}

@property CGPoint centerPoint;

-(void)update;

@property float speedMultiplier;

@end
