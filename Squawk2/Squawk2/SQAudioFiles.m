//
//  SQAudioFiles.m
//  Squawk2
//
//  Created by Nate Parrott on 3/8/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioFiles.h"

@implementation SQAudioFiles

+(void)load {
    [self blipSound];
}
+(AVAudioPlayer*)blipSound {
    static AVAudioPlayer* player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"blip1-loud" withExtension:@"wav"] error:nil];
        player.volume = 0.3;
    });
    return player;
}
+(AVAudioPlayer*)playbackDoneSound {
    static AVAudioPlayer* player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"melodic1_affirm" withExtension:@"wav"] error:nil];
    });
    return player;
}
+(AVAudioPlayer*)blipCountdownSound {
    static AVAudioPlayer* player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"longblips2" withExtension:@"wav"] error:nil];
    });
    return player;
}
+(AVAudioPlayer*)loadingLoop {
    static AVAudioPlayer* player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"slow_beep" withExtension:@"wav"] error:nil];
    });
    player.volume = 0.4;
    player.numberOfLoops = -1;
    return player;
}

@end
