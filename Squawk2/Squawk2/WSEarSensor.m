//
//  WSMotionSensor.m
//  Squawk
//
//  Created by Nate Parrott on 2/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSEarSensor.h"
#import "NSDate+MonotonicTime.h"
#import "RACSignal+MustStayTrue.h"
@implementation WSEarSensor

+(WSEarSensor*)shared {
    static WSEarSensor* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [WSEarSensor new];
    });
    return shared;
}
-(id)init {
    self = [super init];
    
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    _isAvailable = [UIDevice currentDevice].proximityMonitoringEnabled;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    if (!_isAvailable) return self;
    
    _queue = [NSOperationQueue new];
    _motionManager = [CMMotionManager new];
    _motionManager.deviceMotionUpdateInterval = 0.1;
    [_motionManager startDeviceMotionUpdatesToQueue:_queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
                
        long double now = [NSDate monotonicTime];
        
        CMAcceleration accel = motion.userAcceleration;
        double intensity = powf(accel.x, 2) + powf(accel.y, 2) + pow(accel.z, 2);
        if (intensity > 0.1) _timeLastSignificantMotion = now;
        
        CMAcceleration grav = motion.gravity;
        BOOL vertical = fabsf(grav.z) < 0.6;
        if (vertical) _timeLastVertical = now;
        
        if ([UIDevice currentDevice].proximityState) _timeLastProximity = now;
        
        BOOL enableProximitySensor = (now-_timeLastSignificantMotion < 0.6 && now-_timeLastVertical < 0.6) || now-_timeLastProximity < 0.6;
        if (enableProximitySensor != [UIDevice currentDevice].proximityMonitoringEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIDevice currentDevice].proximityMonitoringEnabled = enableProximitySensor;
            });
        }
        
        BOOL triggeredRaise = _timeLastProximity==now && _timeLastVertical==now;
        BOOL raisedToEar = triggeredRaise || (_isRaisedToEar && _timeLastProximity==now);
        if (raisedToEar != _isRaisedToEar) self.isRaisedToEar = raisedToEar;
        
    }];
    
    return self;
}

@end
