//
//  SQBlockAction.h
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQAudioAction.h"

@interface SQBlockAction : SQAudioAction

@property(strong)void(^block)();

+(SQAudioAction*)startPlaybackPrompt;
+(SQAudioAction*)startRecordingPrompt;
+(SQAudioAction*)doneRecordingPrompt;
+(SQAudioAction*)donePlayingPrompt;

@end
