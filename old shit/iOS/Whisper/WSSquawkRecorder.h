//
//  WSAudio.h
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WSAppDelegate.h"

@interface WSSquawkRecorder : NSObject <AVAudioRecorderDelegate> {
    AVAudioRecorder* _recorder;
    NSURL* _url;
    NSTimeInterval _recordingStartDate;
    BOOL _cancelled;
    AVAudioPlayer* _promptSoundPlayer;
}

+(void)getInitializedAudioRecorder:(AVAudioRecorder**)recorder url:(NSURL**)url;
+(NSTimeInterval)maxDuration;
+(NSTimeInterval)postStopRecordingDelay;

-(BOOL)startRecording;
@property(strong)NSArray* recipientPhoneNumbers;
-(void)stopRecording;
-(void)cancelRecording;

@property(strong)WSGenericCallback onFinish;

-(void)sendAudioFileAtURL:(NSURL*)url completed:(WSGenericCallback)callback;

@property BOOL isEarDriven;

@end
