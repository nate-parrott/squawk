//
//  SQOnboardingPage.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQOnboardingPage.h"

@interface SQOnboardingPage ()

@end

@implementation SQOnboardingPage

-(void)showMessage:(NSString*)message title:(NSString*)title {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}
-(void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundColor = self.view.backgroundColor;
    self.view.backgroundColor = [UIColor clearColor];
}
-(void)animateInWithDuration:(NSTimeInterval)duration {
    
}
-(void)animateOutWithDuration:(NSTimeInterval)duration {
    
}

@end
