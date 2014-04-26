//
//  WSAudioPlayer.m
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSAudioPlayer.h"

@implementation WSAudioPlayer

-(void)startWithData:(NSData*)data {
    NSError* error;
    _player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    _player.delegate = self;
    if (error || ![_player play]) {
        self.error = error;
        self.onFinish();
    }
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    self.error = error;
    self.onFinish();
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.onFinish();
}
-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.onFinish();
}
-(void)cancel {
    if (_player) {
        _player.delegate = nil;
        [_player stop];
    } else if (_synth) {
        _synth.delegate = nil;
        [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}
-(void)startWithUtterance:(AVSpeechUtterance*)utterance {
    _synth = [[AVSpeechSynthesizer alloc] init];
    _synth.delegate = self;
    [_synth speakUtterance:utterance];
}

@end
