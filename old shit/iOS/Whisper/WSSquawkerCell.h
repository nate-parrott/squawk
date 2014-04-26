//
//  WSCellTableViewCell.h
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NPContact.h"
#import "WSConcentricCirclesViewAdvancedHD2014.h"
@class WSMessageSender;
@class WSMainViewController;
#import "WSSquawkRecorder.h"
#import "WSAudioPlayer.h"

typedef enum {
    WSCellStatePlayback=1,
    WSCellStateRecording=2,
    WSCellStateSilent=3
} WSCellState;

@interface WSSquawkerCell : UITableViewCell {
    BOOL _setupYet;
    
    BOOL _actionWasStartedByRaiseToEar; // record or playback action
    
    IBOutlet UIView* _playbackView;
    WSAudioPlayer* _audioPlayer;
    WSConcentricCirclesViewAdvancedHD2014* _playbackCircles;
    IBOutlet UIButton* _cancelPlaybackButton;
    
    BOOL _recordingCancelled;
    IBOutlet UIView* _recordingView;
    WSConcentricCirclesViewAdvancedHD2014* _circles;
    UIView* _redCircle;
    WSSquawkRecorder* _audioRecorder;
    
    uint64_t _timeOfLastPlaybackCancel; // so that when we get a download completion callback, we know if the playback has been cancelled
    
    IBOutlet UIButton* _confirmationButton;
    
    BOOL _needsDisplayUpdate;
}

@property(nonatomic)WSCellState state;

@property(strong)IBOutlet UILabel *label;

@property(strong)UIButton* recordingButton;

-(void)cancel;
-(IBAction)tapDown:(id)sender;
-(IBAction)tapUp:(id)sender;

-(IBAction)startRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;
-(IBAction)cancelRecording:(id)sender;

-(void)startPlayback;
-(IBAction)endPlayback:(id)sender;
-(NSArray*)playlist;
-(void)updateDisplay;

-(NSArray*)phoneNumbers;

@property(nonatomic)BOOL recordingUIVisible;
@property(nonatomic)BOOL playbackUIVisible;
@property(nonatomic)BOOL confirmationUIVisible;
-(IBAction)confirm:(id)sender;

@property(weak,nonatomic)WSMainViewController* mainVC;

+(void)gotUnreadCount:(int)count;
+(BOOL)hasSquawkBeenListenedTo:(PFObject*)squawk;
+(void)listenedToSquawk:(PFObject*)squawk;

@property BOOL visible;

@property(nonatomic)BOOL upToEar;

@end
