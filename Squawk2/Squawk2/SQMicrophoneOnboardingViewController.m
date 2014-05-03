//
//  SQMicrophoneOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQMicrophoneOnboardingViewController.h"
#import "SQOnboardingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SQGalleryView.h"
#import "WSEarSensor.h"
#import "SQBlockAction.h"

@interface SQMicrophoneOnboardingViewController () {
    SQAudioAction* _lastAction;
    AVSpeechSynthesizer* _synthesizer;
    IBOutlet UILabel *_listenDescription, *_recordDescription, *_raiseToSquawkDescription;
}

@property(weak)IBOutlet SQGalleryView* gallery;

@end

@implementation SQMicrophoneOnboardingViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _raiseToSquawkDescription.text = NSLocalizedString(@"Or, instead of pressing the button, just hold the phone to your ear.\n\nTry it.", @"");
    _listenDescription.text = NSLocalizedString(@"When you've got a squawk, the button turns blue. Hold it down to play.", @"");
    _recordDescription.text = NSLocalizedString(@"Send a squawk by holding down the red button.", @"");
    
    [self.nextButton setTitle:NSLocalizedString(@"Allow access to microphone", @"") forState:UIControlStateNormal];
    
    if ([WSEarSensor shared].isAvailable) {
        RACSignal* raiseToEar = [[RACObserve([WSEarSensor shared], isRaisedToEar) filter:^BOOL(id value) {
            return [value boolValue];
        }] deliverOn:[RACScheduler mainThreadScheduler]];
        [self rac_liftSelector:@selector(doRaiseToSquawkDemo:) withSignals:raiseToEar, nil];
        
        RACSignal* loweredFromEar = [[RACObserve([WSEarSensor shared], isRaisedToEar) filter:^BOOL(id value) {
            return ![value boolValue];
        }] deliverOn:[RACScheduler mainThreadScheduler]];
        [self rac_liftSelector:@selector(cancelRaiseToSquawkDemo:) withSignals:loweredFromEar, nil];
        
    } else {
        [self.gallery removeViewAtIndex:2];
    }
}

-(void)doRaiseToSquawkDemo:(id)_ {
    if (!_lastAction && !_synthesizer) {
        AppDelegate.tryToRecord = YES;
        
        _lastAction = [SQBlockAction startPlaybackPrompt];
        [_lastAction start];
        
        _synthesizer = [AVSpeechSynthesizer new];
        AVSpeechUtterance* utterance = [AVSpeechUtterance speechUtteranceWithString:NSLocalizedString(@"That's it! When you've received a squawk, it'll play when you put the phone to your head. If you don't have one, it'll start recording a new squawk, which will be sent when you put it down. To respond to a squawk after you've listened to one, put the phone down and pick it up again.", @"")];
        utterance.preUtteranceDelay = 0.03;
        utterance.rate = 0.3;
        [_synthesizer speakUtterance:utterance];
    }
}
-(void)cancelRaiseToSquawkDemo:(id)_ {
    if (_lastAction) {
        [_lastAction stop];
        _lastAction = nil;
    }
    if (_synthesizer) {
        [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        _synthesizer = nil;
    }
}

-(IBAction)done:(id)sender {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate.hasRecordPermission = granted;
            if (granted) {
                [self.owner nextPage];
            } else {
                [self showMessage:NSLocalizedString(@"You can give Squawk access to your microphone in the Settings app, under Privacy.", @"") title:NSLocalizedString(@"Squawk doesn't have access to your microphone", @"")];
            }
        });
    }];
}

@end
