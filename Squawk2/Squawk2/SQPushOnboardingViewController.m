//
//  SQPushOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQPushOnboardingViewController.h"
#import "SQOnboardingViewController.h"

@interface SQPushOnboardingViewController () <UIAlertViewDelegate>

@end

@implementation SQPushOnboardingViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushStatusChanged) name:SQPushSetupStatusChangedNotification object:nil];
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)pushStatusChanged {
    if ([AppDelegate registeredForPushNotifications]) {
        [self.owner nextPage];
    } else {
        [self showDenialMessage];
    }
}
-(IBAction)setupPush:(id)sender {
#if TARGET_IPHONE_SIMULATOR
    [self.owner nextPage];
    return;
#endif
    if ([AppDelegate registeredForPushNotifications]) {
        [self.owner nextPage];
    } else if (AppDelegate.deniedPushNotificationAccess) {
        [self showDenialMessage];
    } else {
        [AppDelegate setupPushNotifications];
    }
}
-(void)showDenialMessage {
    [self showMessage:NSLocalizedString(@"You can turn on push notifications for Squawk in Settings, under Notification Center.", @"") title:NSLocalizedString(@"Push notifications are turned off for Squawk", @"")];
}
-(IBAction)skipPush:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you don't want notifications?", @"") message:NSLocalizedString(@"Squawk isn't really useful without them. We'll only send you notifications when your friends join or message you.", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Sure, turn on notifications", @"") otherButtonTitles:NSLocalizedString(@"No thanks", @""), nil];
    [alert show];
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self setupPush:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SQRefusedPushNotifications"];
        [self.owner nextPage];
    }
}

@end
