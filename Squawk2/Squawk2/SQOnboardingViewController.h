//
//  SQOnboardingViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQOnboardingPage;

@interface SQOnboardingViewController : UIViewController

-(void)nextPage;
@property(strong)SQOnboardingPage* currentPage;

@end
