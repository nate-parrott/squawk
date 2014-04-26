//
//  WSWelcomeViewController.h
//  Whisper
//
//  Created by Nate Parrott on 1/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface WSWelcomeViewController : UIViewController <UITextFieldDelegate, MFMessageComposeViewControllerDelegate> {
    MFMessageComposeViewController* _messageSender;
    
    IBOutlet UILabel* _useYourVoiceLabel;
    
    IBOutlet UIActivityIndicatorView* _loader;
    BOOL _polling;
    IBOutlet UIButton* _startButton;
    
    IBOutlet UIButton* _checkButton;
    
    NSString* _password;
    
    IBOutlet UITextField* _nicknameField;
    
    IBOutlet UILabel* _verificationInstructionsLabel;
    
    int _tryLoginCount;
}

-(IBAction)verify:(id)sender;

@property(nonatomic) BOOL working;

-(IBAction)check:(id)sender;

@end
