//
//  WSCellTableViewCell.m
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSSquawkerCell.h"
#import "ConvenienceCategories.h"
#import "WSAppDelegate.h"
#import "WSMainViewController.h"
#import "WSToastNotificationView.h"
#import "WSMessageSender.h"
#import <mach/mach_time.h>
#import "WSAudioRecorderCache.h"
#import "WSSquawkRecorder.h"
#import "WSAppDelegate+GlobalUIExtensions.h"

@implementation WSSquawkerCell

#pragma mark State
-(void)setState:(WSCellState)state {
    if (_state == state) return;
    _state = state;
    
    self.recordingUIVisible = state==WSCellStateRecording;
    self.playbackUIVisible = state==WSCellStatePlayback;
    if (state!=WSCellStateRecording) {
        _audioRecorder = nil;
    }
    if (state!=WSCellStatePlayback) {
        _timeOfLastPlaybackCancel = mach_absolute_time();
        [_audioPlayer cancel];
        _audioPlayer = nil;
    }
    if (state!=WSCellStateSilent) {
        [self.mainVC cancelAllBut:self];
    }
    if (state==WSCellStateSilent && _needsDisplayUpdate) {
        _needsDisplayUpdate = NO;
        [self updateDisplay];
    }
    [self.mainVC cellStateUpdated];
}

/*-(void)prepareForReuse {
    [super prepareForReuse];
    self.confirmationUIVisible = NO;
    self.state = WSCellStateSilent;
}*/
-(IBAction)tapDown:(id)sender {
    if (self.state==WSCellStateSilent && [self playlist].count) {
        _actionWasStartedByRaiseToEar = NO;
        [self startPlayback];
    }
}
-(IBAction)tapUp:(id)sender {
    [self.mainVC highlightCell:self];
}
-(void)cancel {
    self.state = WSCellStateSilent;
}
-(NSArray*)playlist {
    return @[];
}
-(void)updateDisplay {
    
}
-(NSArray*)phoneNumbers {
    return nil;
}
#pragma mark Playback
-(void)startPlayback {
    [self playNextMessage];
}
-(void)setPlaybackUIVisible:(BOOL)playbackUIVisible {
    if (playbackUIVisible == _playbackUIVisible) return;
    _playbackUIVisible = playbackUIVisible;
    if (playbackUIVisible) {
        self.confirmationUIVisible = YES;
        
        _playbackView.hidden = NO;
        _playbackView.alpha = 0;
        _playbackView.backgroundColor = [UIColor colorWithRed:0.976 green:0.843 blue:0.404 alpha:1.000];
        _playbackView.clipsToBounds = YES;
        _playbackCircles = [WSConcentricCirclesViewAdvancedHD2014 new];
        [_playbackView insertSubview:_playbackCircles atIndex:0];
        _playbackCircles.frame = _playbackView.bounds;
        _playbackCircles.centerPoint = [_cancelPlaybackButton center];
        [_playbackCircles update];
        [UIView animateWithDuration:0.3 animations:^{
            _playbackView.alpha = 1;
        } completion:^(BOOL finished) {
            _playbackView.hidden = NO;
        }];
    } else {        
        UIView* playbackCircles = _playbackCircles;
        _playbackCircles = nil;
        [UIView animateWithDuration:0.3 animations:^{
            _playbackView.alpha = 0;
        } completion:^(BOOL finished) {
            _playbackView.hidden = YES;
            [playbackCircles removeFromSuperview];
        }];
    }
}
-(IBAction)endPlayback:(id)sender {
    _needsDisplayUpdate = YES;
    PFObject* msg = self.playlist.firstObject;
    if (msg) [WSSquawkerCell listenedToSquawk:msg];
    self.state = WSCellStateSilent;
}
-(void)playNextMessage {
    if (_audioPlayer) return;
    NSArray* unread = self.playlist;
    if (unread.count) {
        self.state = WSCellStatePlayback;
        self.confirmationUIVisible = YES;
        PFObject* msg = unread.firstObject;
        PFFile* file = [msg valueForKey:@"file"];
        __block uint64_t downloadStarted = mach_absolute_time();
        _playbackCircles.speedMultiplier = 0.05;
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            _playbackCircles.speedMultiplier = 1.0;
            if (!error && data && downloadStarted > _timeOfLastPlaybackCancel) {
                _audioPlayer = [WSAudioPlayer new];
                _audioPlayer.onFinish = ^() {
                    BOOL errored = !!_audioPlayer.error;
                    if (errored) {
                        [self handlePlaybackError:_audioPlayer.error];
                    }
                    _audioPlayer = nil;
                    // mark as listened:
                    PFObject* msg = [self playlist].firstObject;
                    [WSSquawkerCell listenedToSquawk:msg];
                    _needsDisplayUpdate = YES;
                    if (!errored) {
                        if (self.playlist.count) {
                            [self playNextMessage];
                        } else {
                            if (self.upToEar) {
                                [self startRecording:nil];
                            } else {
                                self.state = WSCellStateSilent;
                            }
                        }
                    }
                };
                [_audioPlayer startWithData:data];
            }
            if (error) {
                if (data && error) {
                    // we got the file, but it's rotten, so throw it out:
                    [WSSquawkerCell listenedToSquawk:msg];
                    _needsDisplayUpdate = YES;
                }
                [self handlePlaybackError:error];
                [AppDelegate trackEventWithCategory:@"error" action:@"playback" label:error.localizedDescription value:nil];
            }
        }];
    } else {
        self.state = WSCellStateSilent;
    }
}
-(void)handlePlaybackError:(NSError*)error {
    [[[UIAlertView alloc] initWithTitle:@"Playback error" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    _needsDisplayUpdate = YES;
    self.state = WSCellStateSilent;
}

#pragma mark Recording
-(void)setRecordingUIVisible:(BOOL)recordingUIVisible {
    if (recordingUIVisible==_recordingUIVisible) return;
    _recordingUIVisible = recordingUIVisible;
    if (recordingUIVisible) {
        _recordingView.hidden = NO;
        _circles = [WSConcentricCirclesViewAdvancedHD2014 new];
        [_recordingView addSubview:_circles];
        _circles.frame = _recordingView.frame;
        _circles.centerPoint = _recordingButton.center;
        _circles.alpha = 0;
        [_circles update];
        
        _redCircle = [UIView new];
        _redCircle.frame = CGRectMake(0, 0, 80, 80);
        _redCircle.backgroundColor = [UIColor colorWithRed:0.973 green:0.294 blue:0.290 alpha:1.000];
        _redCircle.layer.cornerRadius = 40;
        _redCircle.center = _circles.centerPoint;
        _redCircle.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [_recordingView addSubview:_redCircle];
        
        _recordingView.clipsToBounds = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                _circles.alpha = 1;
                _redCircle.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
            }];
        });
    } else {
        UIView* circles = _circles;
        UIView* redCircle = _redCircle;
        _circles = nil;
        _redCircle = nil;
        [UIView animateWithDuration:0.3 animations:^{
            circles.alpha = 0;
            redCircle.transform = CGAffineTransformMakeScale(0.01, 0.01);
        } completion:^(BOOL finished) {
            [circles removeFromSuperview];
            [redCircle removeFromSuperview];
            _recordingView.hidden = YES;
        }];
    }
}
-(IBAction)startRecording:(id)sender {
    _actionWasStartedByRaiseToEar = sender != _recordingButton;
    if ([AppDelegate queuedAudioFileURL] == nil) {
        self.state = WSCellStateRecording;
        _audioRecorder = [WSSquawkRecorder new];
        _audioRecorder.isEarDriven = self.upToEar;
        _audioRecorder.recipientPhoneNumbers = [self phoneNumbers];
        if (![_audioRecorder startRecording]) {
            self.state = WSCellStateSilent;
        }
        __weak WSSquawkerCell* weakSelf = self;
        [_audioRecorder setOnFinish:^ id (id _) {
            weakSelf.state = WSCellStateSilent;
            return nil;
        }];
    }
}
-(IBAction)stopRecording:(id)sender {
    if ([AppDelegate queuedAudioFileURL] != nil) {
        _audioRecorder = [WSSquawkRecorder new];
        _audioRecorder.recipientPhoneNumbers = [self phoneNumbers];
        [_audioRecorder sendAudioFileAtURL:AppDelegate.queuedAudioFileURL completed:^id(id x) {
            return nil;
        }];
        AppDelegate.queuedAudioFileURL = nil;
    } else {
        [_audioRecorder stopRecording];
    }
}
-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    [self cancelRecording:nil];
}
-(IBAction)cancelRecording:(id)sender {
    [_audioRecorder cancelRecording];
}
#pragma mark Confirmation UI
-(void)setConfirmationUIVisible:(BOOL)confirmationUIVisible {
    if (confirmationUIVisible != _confirmationUIVisible) {
        _confirmationUIVisible = confirmationUIVisible;
        if (confirmationUIVisible) {
            _confirmationButton.hidden = NO;
            _confirmationButton.alpha = 0;
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                _confirmationButton.alpha = 1;
            } completion:nil];
        } else {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                _confirmationButton.alpha = 0;
            } completion:^(BOOL finished) {
                _confirmationButton.hidden = YES;
            }];
        }
    }
}
-(IBAction)confirm:(id)sender {
    [AppDelegate trackEventWithCategory:@"ui_action" action:@"sent_confirmation" label:nil value:nil];
    [AppDelegate showCheckmarkAnimationStartingFromButton:sender];
    self.confirmationUIVisible = NO;
}
#pragma mark Accessibility
-(NSString*)accessibilityLabel {
    return self.label.text;
}

#pragma mark Squawk listened tracking
// we have to track listened squawks manually because Parse doesn't always de-duplicate PFObjects with the same ID
NSNumber* _WSUnreadCount = nil;

+(NSMutableSet*)listenedSquawkIDs {
    static NSMutableSet* ids = nil;
    if (!ids) {
        ids = [NSMutableSet new];
    }
    return ids;
}
+(BOOL)hasSquawkBeenListenedTo:(PFObject*)squawk {
    return [[squawk valueForKey:@"listened"] boolValue] || [[self listenedSquawkIDs] containsObject:squawk.objectId] || [[[squawk valueForKey:@"sender"] objectId] isEqualToString:[PFUser currentUser].objectId];
}
+(void)listenedToSquawk:(PFObject*)squawk {
    [squawk setValue:@YES forKey:@"listened"];
    [squawk saveEventually];
    [[self listenedSquawkIDs] addObject:squawk.objectId];
    if (_WSUnreadCount) {
        int newUnreadCount = _WSUnreadCount.intValue - 1;
        if (newUnreadCount != [[PFInstallation currentInstallation] badge]) {
            [[PFInstallation currentInstallation] setBadge:newUnreadCount];
            [[PFInstallation currentInstallation] saveInBackground];
        }
        [self gotUnreadCount:newUnreadCount];
    }
}
+(void)gotUnreadCount:(int)count {
    _WSUnreadCount = @(count);
}
#pragma mark Ear session
-(void)setMainVC:(WSMainViewController *)mainVC {
    if (_mainVC == mainVC) return;
    _mainVC = mainVC;
    RAC(self,  upToEar) = [mainVC.cellForRaiseToSquawk map:^id(id value) {
        return @([value isEqual:self]);
    }];
}
-(void)setUpToEar:(BOOL)upToEar {
    if (upToEar == _upToEar) return;
    _upToEar = upToEar;
    if (upToEar) {
        if (self.state == WSCellStateSilent) {
            _actionWasStartedByRaiseToEar = NO;
            if (self.playlist.count) {
                [self startPlayback];
            } else {
                [self startRecording:nil];
            }
        }
    } else {
        if (_actionWasStartedByRaiseToEar) {
            if (self.state == WSCellStatePlayback) {
                [self cancel];
            } else if (self.state == WSCellStateRecording) {
                [self stopRecording:nil];
            }
        }
    }
}

@end
