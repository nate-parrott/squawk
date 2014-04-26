//
//  SQAudioRecordingAction.h
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioAction.h"
#import <AVFoundation/AVFoundation.h>

#define MIN_RECORDING_DURATION 0.9

@class SQAudioRecordingAction;
@protocol SQAudioRecordingActionDelegate <SQAudioActionDelegate>

-(void)audioActionDidAbortForTooShortRecording:(SQAudioRecordingAction*)action;
-(void)audioActionDidRecordSquawk:(SQAudioRecordingAction*)action;

@end


@interface SQAudioRecordingAction : SQAudioAction <AVAudioRecorderDelegate, NSURLSessionDelegate> {
    AVAudioRecorder* _recorder;
    NSURL* _fileURL;
    NSTimeInterval _started;
    SQStatusViewCard* _statusView;
}

@property(strong)NSArray* recipients;

@property(weak)id<SQAudioRecordingActionDelegate> delegate;

@end
