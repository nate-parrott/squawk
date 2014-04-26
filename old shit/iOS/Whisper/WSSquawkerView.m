//
//  WSSquawkerView.m
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSSquawkerView.h"
#import "WSMessageSender.h"
#import "WSBetaUIViewController.h"

@implementation WSSquawkerView

+(WSSquawkerView*)view {
    static UINib* nib = nil;
    if (!nib) {
        nib = [UINib nibWithNibName:@"WSSquawkerView" bundle:nil];
    }
    return [nib instantiateWithOwner:nil options:nil][0];
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    
    _expandedContents.alpha = 0;
    
    /*RAC(self, audioOn) = [RACSignal combineLatest:@[RACObserve(self, expanded), RACObserve(self, tapDown), [AppDelegate upToEar], RACObserve([UIApplication sharedApplication], applicationState)] reduce:^id(NSNumber* expanded, NSNumber* tapDown, NSNumber* proximity, NSNumber* appState){
        return @(expanded.boolValue && (tapDown.boolValue || proximity.boolValue) && appState.integerValue==UIApplicationStateActive);
    }];*/
    RAC(self, backgroundColor) = [RACObserve(self, audioOn) map:^id(id value) {
        return [value boolValue]? [UIColor greenColor] : [UIColor whiteColor];
    }];
    RAC(_nameLabel, text) = [RACObserve(self, squawker) map:^id(id value) {
        return [value displayName];
    }];
    RAC(_nicknameLabel, text) = [RACObserve(self, squawker) map:^id(id value) {
        return [value nickname];
    }];
    RAC(_durationLabel, text) = [RACObserve(self, unread) map:^id(id value) {
        int count = [value count];
        return [NSString stringWithFormat:@"%i", count];
    }];
    RAC(_detailLabel, text) = [RACObserve(self, unread) map:^id(id value) {
        return [value count]>0? @"Tap or hold to head to play" : @"Tap or hold to head to record";
    }];
}
#pragma mark Data
-(void)setSquawker:(WSMessageSender *)squawker {
    _squawker = squawker;
    self.unread = squawker.unread;
}
-(void)prepareForReuse {
    self.squawker = nil;
    _expandedContents.alpha = 0;
}
#pragma mark UI
-(IBAction)tapped:(UITapGestureRecognizer*)gestureRec {
    if (!self.expanded && gestureRec.state == UIGestureRecognizerStateRecognized) {
        [self expandSelf];
    }
}
-(void)expandSelf {
    NSDictionary* viewsForIndices = self.owner.table.cellsForIndices;
    for (NSNumber* idx in viewsForIndices) {
        if (viewsForIndices[idx] == self) {
            [self.owner.table scrollToCellAtIndex:idx.integerValue animated:YES];
        }
    }
}
-(IBAction)touchDown:(id)sender {
    self.tapDown = YES;
}
-(IBAction)touchUp:(id)sender {
    self.tapDown = NO;
}
-(void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _expandedContents.alpha = expanded? 1 : 0;
    } completion:^(BOOL finished) {
        
    }];
}
#pragma mark Playback/record
-(BOOL)playbackMode {
    return self.squawker.unread.count>0;
}
-(void)setAudioOn:(BOOL)audioOn {
    if (_audioOn==audioOn) return;
    _audioOn = audioOn;
    
    if (audioOn) {
        _audioBeganInPlaybackMode = [self playbackMode];
        [self nextAudioAction];
    } else {
        if (_audioCancelCallback) _audioCancelCallback();
        _audioCancelCallback = nil;
    }
}
-(void)nextAudioAction {
    if ([self playbackMode]) {
        [self playNextMessage];
    } else {
        if (_audioBeganInPlaybackMode) {
            [self playPreRecordingMessage];
        } else {
            [self startRecording];
        }
    }
}
#pragma mark Playback
-(void)playNextMessage {
    PFObject* msg = self.squawker.unread.firstObject;
    PFFile* file = [msg valueForKey:@"file"];
    __block BOOL cancelled = NO;
    _audioCancelCallback = ^() {
        cancelled = YES;
    };
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!cancelled) {
            if (data && !error) {
                _audioPlayer = [WSAudioPlayer new];
                __weak id weakSelf = self;
                _audioPlayer.onFinish = ^() {
                    if (_audioPlayer.error) {
                        // TODO
                    } else {
                        [WSSquawkerCell listenedToSquawk:self.unread.firstObject];
                        self.unread = self.squawker.unread;
                        [weakSelf nextAudioAction];
                    }
                    _audioPlayer = nil;
                };
                _audioCancelCallback = ^() {
                    [_audioPlayer cancel];
                    _audioPlayer = nil;
                };
                [_audioPlayer startWithData:data];
            } else {
                // TODO
            }
        }
    }];
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    // TODO
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        PFObject* msg = self.squawker.unread.firstObject;
        [WSSquawkerCell listenedToSquawk:msg];
        self.unread = self.squawker.unread;
        [self nextAudioAction];
    }
}
#pragma mark Recording
-(void)startRecording {
    _audioCancelCallback = ^() {
        [_squawkRecorder stopRecording];
        _squawkRecorder = nil;
    };
    _squawkRecorder = [[WSSquawkRecorder alloc] init];
    _squawkRecorder.recipientPhoneNumbers = @[self.squawker.preferredPhoneNumber];
    [_squawkRecorder setOnFinish:^id(id success) {
        if ([success boolValue]) {
            
        } else {
            // TODO
        }
        _squawkRecorder = nil;
        return nil;
    }];
    if (![_squawkRecorder startRecording]) {
        // TODO
    }
}
-(void)playPreRecordingMessage {
    _audioCancelCallback = ^() {
        [_audioPlayer cancel];
        _audioPlayer = nil;
    };
    _audioPlayer = [WSAudioPlayer new];
    _audioPlayer.onFinish = ^() {
        _audioBeganInPlaybackMode = NO;
        _audioPlayer = nil;
        [self nextAudioAction];
    };
    AVSpeechUtterance* utterance = [AVSpeechUtterance speechUtteranceWithString:NSLocalizedString(@"Reply in 3, 2, 1", @"")];
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate;// AVSpeechUtteranceMinimumSpeechRate + (AVSpeechUtteranceMaximumSpeechRate-AVSpeechUtteranceMinimumSpeechRate) * 0.6;
    [_audioPlayer startWithUtterance:utterance];
}

@end
