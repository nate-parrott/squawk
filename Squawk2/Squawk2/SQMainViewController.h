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
#import "SQStatusView.h"
#import "SQAnimatedBird.h"

typedef enum {
    SQNoInteraction,
    SQPressedRow,
    SQPressedButton,
    SQRaisedToEar
} SQInteractionMode;

@interface SQMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SQAudioActionDelegate, SQAudioRecordingActionDelegate, UIViewControllerTransitioningDelegate> {
    RACSubject* _tableViewReloaded;
    
    IBOutlet UIView *_headerView;
    
    IBOutlet UIView* _errorContainer;
    IBOutlet UILabel* _errorLabel;
    
    IBOutlet NSLayoutConstraint* _headerTopOffset;
    IBOutlet NSLayoutConstraint* _searchBarTopOffset;
        
    IBOutlet SQStatusView* _statusView;
    
    BOOL _setupLoginHooks;
    
    IBOutlet UIButton* _inviteFriendsPrompt;
    
    NSString* _mostRecentSquawkID;
    
    IBOutlet SQAnimatedBird* _bird;
    
    IBOutlet UIView* _raiseToSquawkHintContainer;
    IBOutlet UILabel* _raiseToSquawkHint;
}

@property(strong)IBOutlet UITableView* tableView;

@property(strong)NSArray* allThreads;
@property(strong)NSArray* threadSections; // filtered by search query

@property(strong)SQThread* selectedThread;
@property(strong)SQThread* pressedThread;
@property(strong)SQThread* interactingWithThread;

@property(strong)NSMutableArray* audioActionQueue;
@property(strong)SQAudioAction* currentAudioAction;

@property SQInteractionMode interactionMode;

@property BOOL tapDown;
@property CGPoint touchPoint;

@property(nonatomic) BOOL playOrRecord;

@property BOOL contactsAuthorization;

@property BOOL loading;

@property BOOL lateEnoughToShowError;

-(IBAction)newThread:(id)sender;

-(void)rippleFromCell:(UITableViewCell*)cell;

@end
