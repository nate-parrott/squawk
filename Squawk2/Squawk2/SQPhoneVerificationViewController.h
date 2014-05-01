//
//  SQPhoneVerificationViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQOnboardingPage.h"
#import "SQShimmerView.h"
#import <MessageUI/MessageUI.h>

@interface SQPhoneVerificationViewController : SQOnboardingPage <MFMessageComposeViewControllerDelegate>

@property(weak)IBOutlet UILabel *errorLabel, *instructionsLabel;
@property(weak)IBOutlet SQShimmerView* loadingView;

@end
