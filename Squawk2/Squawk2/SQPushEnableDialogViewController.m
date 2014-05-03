//
//  SQPushEnableDialogViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQPushEnableDialogViewController.h"
#import "UIViewController+SoftModal.h"

@interface SQPushEnableDialogViewController ()

@end

@implementation SQPushEnableDialogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppDelegate setupPushNotifications];
    
    [_closeButton setTitle:NSLocalizedString(@"Close", @"") forState:UIControlStateNormal];
    
    RACSignal* gotAccess = [RACObserve(AppDelegate, pushNotificationsEnabled) filter:^BOOL(id value) {
        return [value boolValue];
    }];
    [self rac_liftSelector:@selector(close:) withSignals:gotAccess, nil];
}
-(IBAction)close:(id)sender {
    [self dismissSoftModal];
}

@end
