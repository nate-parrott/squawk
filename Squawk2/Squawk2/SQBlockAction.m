//
//  SQBlockAction.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQBlockAction.h"
#import "SQAudioFiles.h"
#import "WSEarSensor.h"

//#define DISABLE_VIBRATION

@implementation SQBlockAction

-(void)start {
    [super start];
    self.block();
    self.block = nil;
    [self.delegate audioActionFinished:self];
}

#pragma mark Canned actions
+(BOOL)supportsVibration {
    return [[UIDevice currentDevice].model isEqualToString:@"iPhone"]; // the best we've got, apparently
}
+(SQBlockAction*)vibrateAction {
    SQBlockAction* action = [SQBlockAction new];
    __weak SQBlockAction* weakAction = action;
    action.block = ^() {
        if ([self supportsVibration]) {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakAction.delegate audioActionFinished:weakAction];
            });
        } else {
            [[SQAudioFiles blipSound] setCurrentTime:0];
            [[SQAudioFiles blipSound] play];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([SQAudioFiles blipSound].duration+0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakAction.delegate audioActionFinished:weakAction];
            });
        }
    };
    return action;
}
+(SQAudioAction*)vibrateOrFallback:(SQAudioAction*)fallback {
#ifdef DISABLE_VIBRATION
    return fallback;
#endif
    if ([self supportsVibration]) {
        return [self vibrateAction];
    } else {
        return fallback;
    }
}
+(SQBlockAction*)actionForPlayingSound:(AVAudioPlayer*)sound {
    SQBlockAction* action = [SQBlockAction new];
    __weak SQBlockAction* weakAction = action;
    action.block = ^() {
        [sound setCurrentTime:0];
        [sound play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([SQAudioFiles blipSound].duration+0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakAction.delegate audioActionFinished:weakAction];
        });
    };
    return action;
}
+(SQAudioAction*)emptyAction {
    SQBlockAction* action = [SQBlockAction new];
    __weak SQBlockAction* weakAction = action;
    action.block = ^() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!weakAction.stopped && !weakAction.cancelled) {
                [weakAction.delegate audioActionFinished:weakAction];
            }
        });
    };
    return action;
}
+(SQAudioAction*)startPlaybackPrompt {
    if ([WSEarSensor shared].isRaisedToEar) {
        return [self vibrateOrFallback:[self actionForPlayingSound:[SQAudioFiles blipSound]]];
    } else {
        return [self emptyAction];
    }
}
+(SQAudioAction*)donePlayingPrompt {
    return [self actionForPlayingSound:[SQAudioFiles playbackDoneSound]];
}
+(SQAudioAction*)startRecordingPrompt {
    if ([WSEarSensor shared].isRaisedToEar) {
        return [self vibrateOrFallback:[self actionForPlayingSound:[SQAudioFiles blipSound]]];
    } else {
        return [self actionForPlayingSound:[SQAudioFiles blipSound]];
    }
}
+(SQAudioAction*)doneRecordingPrompt {
    if ([WSEarSensor shared].isRaisedToEar) {
        return [self vibrateOrFallback:[self actionForPlayingSound:[SQAudioFiles playbackDoneSound]]];
    } else {
        return [self actionForPlayingSound:[SQAudioFiles playbackDoneSound]];
    }
}


@end
