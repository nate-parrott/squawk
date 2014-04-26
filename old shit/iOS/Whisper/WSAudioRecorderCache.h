//
//  WSAudioRecorderCache.h
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface WSAudioRecorderCache : NSObject {
    AVAudioRecorder* _recorder;
    NSURL* _currentRecorderDestURL;
    int _lastFileID;
    BOOL _loadInProgress;
}

+(WSAudioRecorderCache*)shared;

@property(strong)AVAudioRecorder* recorder;
@property(strong)NSURL* recorderURL;

-(void)newRecorder;

@end
