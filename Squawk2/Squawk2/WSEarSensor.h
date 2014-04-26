//
//  WSMotionSensor.h
//  Squawk
//
//  Created by Nate Parrott on 2/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>
#import <CoreMotion/CoreMotion.h>

@interface WSEarSensor : NSObject {
    CMMotionManager* _motionManager;
    NSOperationQueue* _queue;
    
    long double _timeLastSignificantMotion, _timeLastVertical, _timeLastProximity;
    
    long long _tick;
}

+(WSEarSensor*)shared;

@property(readonly)BOOL isAvailable;
@property BOOL isRaisedToEar;

@end
