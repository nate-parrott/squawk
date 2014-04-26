//
//  SQMainViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQThread.h"
#import "SQAudioAction.h"
#import "SQAudioPlayerAction.h"
#import "SQAudioRecordingAction.h"
#import "SQBlockAction.h"
#import "SQBlurredStatusView.h"
#import "SQSquawkBar.h"

typedef enum {
    SQNoInteraction,
    SQPressedRow,
    SQPressedButton,
    SQRaisedToEar
} SQInteractionMode;

NSString* SQMicrophoneStatusGranted;

@interface SQMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SQAudioActionDelegate, SQAudioRecordingActionDelegate, SQSquawkBarDelegate> {
    IBOutlet UIView* _selectorBar;
    RACSubject* _tableViewReloaded;
    
    IBOutlet UIView *_headerView;
    
    IBOutlet UIView* _errorContainer;
    IBOutlet UILabel* _errorLabel;
    
    IBOutlet NSLayoutConstraint* _headerTopOffset;
    IBOutlet NSLayoutConstraint* _searchBarTopOffset;
        
    IBOutlet SQBlurredStatusView* _statusView;
    
    BOOL _setupLoginHooks;
    
    IBOutlet UIButton* _inviteFriendsPrompt;
    
    IBOutlet UILabel* _squawksReloadAutomatically;
    
    NSString* _mostRecentThreadIdentifier;
}

@property(strong)IBOutlet UITableView* tableView;

@property(strong)NSArray* allThreads;
@property(strong)NSArray* threadSections; // filtered by search query

@property(weak)IBOutlet SQSquawkBar* squawkBar;

@property(strong)SQThread* selectedThread;
@property(strong)SQThread* pressedThread;
@property(strong)SQThread* interactingWithThread;

@property(strong)NSMutableArray* audioActionQueue;
@property(strong)SQAudioAction* currentAudioAction;

@property SQInteractionMode interactionMode;

@property BOOL tapDown;

@property(nonatomic) BOOL playOrRecord;

@property BOOL microphoneAuthorization, contactsAuthorization;

@property BOOL loading;

@property BOOL lateEnoughToShowError;

@end
