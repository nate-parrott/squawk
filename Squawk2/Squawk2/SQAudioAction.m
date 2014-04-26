//
//  SQAudioAction.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioAction.h"

NSString* SQAudioActionStatusChanged = @"SQAudioActionStatusChanged";

@implementation SQAudioAction

-(void)start {
    self.started = YES;
}
-(void)stop {
    self.stopped = YES;
    self.delegate = nil;
}
-(void)abort {
    self.cancelled = YES;
    self.delegate = nil;
}
-(SQStatusViewCard*)statusView {
    return nil;
}
-(void)refreshDisplay {
    
}

@end
