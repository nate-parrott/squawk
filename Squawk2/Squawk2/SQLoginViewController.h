//
//  SQLoginViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SQShimmerView.h"

typedef enum {
    SQLoginNotStarted = 0,
    SQLoginSendingVerificationText = 1,
    SQLoginAskingUserToSendVerification = 2,
    SQLoginCheckingForVerification
} SQLoginState;

#define MAX_LOGIN_TRIES 10

@interface SQLoginViewController : UIViewController <MFMessageComposeViewControllerDelegate> {
    IBOutlet SQShimmerView* _loadingIndicator;
    IBOutlet UIView* _verifyBar;
    IBOutlet UILabel* _textLabel;
    IBOutlet UIButton* _sendVerificationButton;
    IBOutlet UIButton* _doneSendingVerificationButton;
    IBOutlet UILabel* _errorLabel;
    IBOutlet UILabel* _letsGetStarted;
    
    MFMessageComposeViewController* _messageComposer;
    
    int _numLoginTries;
}

@property SQLoginState loginState;

-(IBAction)sendVerificationText:(id)sender;

-(IBAction)tryLogin:(id)sender;

@property(strong)NSString* errorMessage;

@property(strong)NSString* secret;

@end
