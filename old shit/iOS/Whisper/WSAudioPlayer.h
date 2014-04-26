//
//  WSAudioPlayer.h
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSAppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface WSAudioPlayer : NSObject <AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate>

-(void)startWithData:(NSData*)data;
-(void)startWithUtterance:(AVSpeechUtterance*)utterance;
@property(strong)WSEmptyCallback onFinish;
@property(strong)NSError* error;
@property(strong)AVAudioPlayer* player;
@property(strong)AVSpeechSynthesizer* synth;
-(void)cancel; // does NOT call onFinish

@end
