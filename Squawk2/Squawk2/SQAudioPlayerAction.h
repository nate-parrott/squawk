//
//  SQAudioPlayerAction.h
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioAction.h"
#import <AVFoundation/AVFoundation.h>

@interface SQAudioPlayerAction : SQAudioAction <AVAudioPlayerDelegate> {
    AVAudioPlayer* _player;
    SQStatusViewCard* _statusView;
}

@property(strong)NSMutableDictionary* squawk;
@property(nonatomic) BOOL loading;

@end
