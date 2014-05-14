//
//  SQAudioRecordingAction.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioRecordingAction.h"
#import "SQBlockAction.h"
#import "SQFriendsOnSquawk.h"
#import "SQAPI.h"
#import "SQSquawkCache.h"
#import "SQStatusView.h"

@implementation SQAudioRecordingAction

+(void)uploadFinished:(NSDictionary*)status {
    // this is only called on error a.t.m.
    if (status[SQBackgroundTaskCallbackErrorKey]) {
        [AppDelegate toast:@"Squawk failed!"];
    }
    [[SQBackgroundTaskManager shared] completedBackgroundTaskCallback];
}

+(NSMutableSet*)runningRecorders {
    static NSMutableSet* recorders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorders = [NSMutableSet new];
    });
    return recorders;
}
+(NSURL*)fileURL {
    static int urlIndex= 0;
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"AudioRecording-%i.m4a", (urlIndex++)%10]];
    return [NSURL fileURLWithPath:path];
}
-(void)start {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.cancelled || self.stopped) return;
        _started = [NSDate timeIntervalSinceReferenceDate];
        _fileURL = [SQAudioRecordingAction fileURL];
        NSError* err = nil;
        NSDictionary* settings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVNumberOfChannelsKey: @1, AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_VariableConstrained, AVEncoderAudioQualityForVBRKey: @(AVAudioQualityLow), AVSampleRateKey: @22050};
        _recorder = [[AVAudioRecorder alloc] initWithURL:_fileURL settings:settings error:&err];
        if (!_recorder || err) {
            [self.delegate audioAction:self failedWithError:err];
            return;
        }
        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;
        [_recorder recordForDuration:MAX_RECORDING_DURATION];
    });
    [super start];
}
-(void)stop {
    if (!_started || [NSDate timeIntervalSinceReferenceDate] - _started < MIN_RECORDING_DURATION) {
        [AppDelegate trackEventWithCategory:@"action" action:@"squawk_aborted_too_short" label:nil value:nil];
        [self.delegate audioActionDidAbortForTooShortRecording:self];
        [self abort];
        return;
    }
    [self.delegate audioActionDidRecordSquawk:self];
    [[SQAudioRecordingAction runningRecorders] addObject:self];
    [_recorder stop];
    [super stop];
}
-(void)abort {
    _recorder.delegate = nil;
    [_recorder stop];
    [super abort];
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    [self.delegate audioAction:self failedWithError:error];
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (!flag) {
        [self.delegate audioAction:self failedWithError:nil];
        [[SQAudioRecordingAction runningRecorders] removeObject:self];
        return;
    }
    // upload:
    [AppDelegate trackEventWithCategory:@"action" action:@"sent_squawk_with_length" label:nil value:@([_recorder currentTime])];
    
    NSMutableArray* recipients = self.recipients.mutableCopy;
    [recipients removeObject:[SQAPI currentPhone]];
    
    NSDictionary* args = @{@"recipients": recipients, @"filename": _fileURL.lastPathComponent, @"duration": @(recorder.currentTime)};
    [SQAPI postInBackground:@"/squawks/send" args:args file:_fileURL callback:SQBackgroundTaskCallbackMake([SQAudioRecordingAction class], @selector(uploadFinished:), @"")];
    DBLog(@"URLSessionStarted");
    [[SQBlockAction doneRecordingPrompt] start];
    
    [[SQFriendsOnSquawk shared] sendInvitesToUsersIfNecessary:recipients prompt:[SQFriendsOnSquawk receivedMessageInvitationPrompt]];
}
-(SQStatusViewCard*)statusView {
    if (!_statusView) {
        _statusView = [[SQStatusViewCard alloc] initWithText:NSLocalizedString(@"Recording", @"") image:[UIImage imageNamed:@"recording-thin"]];
        _statusView.circleSpeed = 1;
    }
    return _statusView;
}
#pragma mark Display
-(void)refreshDisplay {
    [_recorder updateMeters];
    double power = [_recorder averagePowerForChannel:0];
    power = MIN(0, MAX(-50, power));
    power = (power+50)/50.0;
    _statusView.circleScale = 1+power;
}

@end
