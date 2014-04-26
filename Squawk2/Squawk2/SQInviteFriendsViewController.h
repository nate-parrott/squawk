//
//  SQInviteFriendsViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 3/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
@import Social;

@interface SQInviteFriendsViewController : UIViewController <MFMessageComposeViewControllerDelegate> {
    IBOutlet UIButton *_sendTextButton, *_facebookButton, *_twitterButton, *_squawkFeedbackButton;
}

-(IBAction)postToFacebook:(id)sender;
-(IBAction)sendText:(id)sender;
-(IBAction)tweet:(id)sender;

-(IBAction)done:(id)sender;

-(IBAction)openWebsite:(id)sender;
-(IBAction)squawkFeedback:(id)sender;

@end
