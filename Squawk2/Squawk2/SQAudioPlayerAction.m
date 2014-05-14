//
//  SQAudioPlayerAction.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAudioPlayerAction.h"
#import "SQSquawkCache.h"
#import "WSPersistentDictionary.h"
#import "SQThread.h"
#import "SQAudioFiles.h"
#import "SQStatusView.h"

@implementation SQAudioPlayerAction

-(void)start {
    self.loading = YES;
    [[SQSquawkCache shared] getDataForSquawk:self.squawk callback:^(NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.stopped || self.cancelled) return;
            if (!data) {
                [self.delegate audioAction:self failedWithError:error];
                return;
            }
            self.loading = NO;
            
            NSError* err = nil;
            _player = [[AVAudioPlayer alloc] initWithData:data error:&err];
            if (err) {
                // corrupt, so delete:
                [SQThread listenedToSquawk:self.squawk];
                [self.delegate audioAction:self failedWithError:err];
                return;
            }
            _player.delegate = self;
            _player.currentTime = [SQAudioPlayerAction timeToResumeSquawk:self.squawk];
            if (![_player play]) {
                [self.delegate audioAction:self failedWithError:err];
                return;
            }
        });
    }];
    [super start];
}
-(void)setLoading:(BOOL)loading {
    if (_loading == loading) return;
    
    _loading = loading;
    [[NSNotificationCenter defaultCenter] postNotificationName:SQAudioActionStatusChanged object:self];
    if (loading) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.loading) {
                [[SQAudioFiles loadingLoop] setCurrentTime:0];
                [[SQAudioFiles loadingLoop] play];
            }
        });
    } else {
        [[SQAudioFiles loadingLoop] stop];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SQStatusViewCard* status = self.statusView;
        status.circleSpeed = loading? 0.3 : 1;
        if (self.loading) {
            status.imageView.image = [[UIImage imageNamed:@"playing-thin"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            status.label.text = NSLocalizedString(@"Loading", @"").uppercaseString;
        } else {
            status.imageView.image = [[UIImage imageNamed:@"playing-thin"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            status.label.text = NSLocalizedString(@"Playing", @"").uppercaseString;
        }
        [status setNeedsLayout];
    });
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    // corrupt file, so mark as read:
    [SQThread listenedToSquawk:self.squawk];
    [self.delegate audioAction:self failedWithError:error];
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!self.stopped && !self.cancelled) {
        [SQThread listenedToSquawk:self.squawk];
        if (flag) {
            [self.delegate audioActionFinished:self];
        } else {
            [self.delegate audioAction:self failedWithError:nil];
        }
    }
}
-(void)stop {
    [super stop];
    self.loading = NO;
    [_player stop];
    [SQAudioPlayerAction stoppedListeningToSquawk:self.squawk atPosition:_player.currentTime];
}
-(void)abort {
    [super abort];
    self.loading = NO;
    [_player stop];
}
#pragma mark Audio place preservation
const NSString* SQSquawkSessionSquawkPlaybackTimes = @"SQSquawkSessionSquawkPlaybackTimes";
+(void)stoppedListeningToSquawk:(NSDictionary*)squawk atPosition:(NSTimeInterval)time {
    NSMutableDictionary* times = [WSPersistentDictionary shared][SQSquawkSessionSquawkPlaybackTimes]? : [NSMutableDictionary new];
    if (time) {
        times[squawk[@"_id"]] = @(time);
    } else {
        [times removeObjectForKey:squawk[@"_id"]];
    }
    [WSPersistentDictionary shared][SQSquawkSessionSquawkPlaybackTimes] = times;
}
+(NSTimeInterval)timeToResumeSquawk:(NSDictionary*)squawk {
    NSNumber* n = [WSPersistentDictionary shared][SQSquawkSessionSquawkPlaybackTimes][squawk[@"_id"]];
    return MAX(0, n.doubleValue - 3);
}
-(SQStatusViewCard*)statusView {
    if (!_statusView) {
        _statusView = [[SQStatusViewCard alloc] initWithText:nil image:nil];
    }
    return _statusView;
}
#pragma mark Display
-(void)refreshDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{
        _statusView.circleSpeed = 1;
    });
}

@end
