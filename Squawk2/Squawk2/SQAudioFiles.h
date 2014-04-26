//
//  SQAudioFiles.h
//  Squawk2
//
//  Created by Nate Parrott on 3/8/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SQAudioFiles : NSObject

+(void)load;
+(AVAudioPlayer*)blipSound;
+(AVAudioPlayer*)blipCountdownSound;
+(AVAudioPlayer*)playbackDoneSound;
+(AVAudioPlayer*)loadingLoop;

@end
