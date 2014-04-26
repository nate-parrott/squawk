//
//  WSAudioRecorderCache.m
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSAudioRecorderCache.h"

@implementation WSAudioRecorderCache

+(WSAudioRecorderCache*)shared {
    static WSAudioRecorderCache* shared = nil;
    if (!shared ) {
        shared = [WSAudioRecorderCache new];
    }
    return shared;
}
-(NSString*)getDestPath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"recording-%i.m4a", (_lastFileID++)%12]];
}
+(NSDictionary*)recorderSettings {
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC)};
}
-(void)newRecorder {
    _recorderURL = [NSURL fileURLWithPath:[self getDestPath]];
    _recorder = [[AVAudioRecorder alloc] initWithURL:self.recorderURL settings:[WSAudioRecorderCache recorderSettings] error:nil];
    NSLog(@"%@", _recorderURL.absoluteString);
    [_recorder prepareToRecord];
}

@end
