//
//  WSSquawkerView.h
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WSSquawkRecorder.h"
#import "WSAudioPlayer.h"
#import "SQExpandingTableView.h"

@class WSMessageSender;
@class WSBetaUIViewController;

@interface WSSquawkerView : UIView <SQExpandingTableViewRowView> {
    IBOutlet UILabel *_nameLabel, *_nicknameLabel, *_durationLabel, *_detailLabel;
    
    IBOutlet UIView* _expandedContents;
    
    WSAudioPlayer* _audioPlayer;
    
    WSSquawkRecorder* _squawkRecorder;
    
    BOOL _audioBeganInPlaybackMode;
    
    WSEmptyCallback _audioCancelCallback;
    
}

+(WSSquawkerView*)view;

@property(strong,nonatomic)WSMessageSender* squawker;
@property(strong)NSArray* unread;

@property(nonatomic)BOOL expanded;

@property(weak)WSBetaUIViewController* owner;

-(IBAction)tapped:(UITapGestureRecognizer*)gestureRec;
@property BOOL tapDown;
-(IBAction)touchDown:(id)sender;
-(IBAction)touchUp:(id)sender;

@property(nonatomic) BOOL audioOn;

@end
