//
//  SQOnboardingPage.h
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQOnboardingViewController;
@interface SQOnboardingPage : UIViewController

@property(weak)SQOnboardingViewController* owner;

@property(weak)IBOutlet UIButton* nextButton;
@property(weak)IBOutlet UIView* backgroundView;

-(void)showMessage:(NSString*)message title:(NSString*)title;

@end
