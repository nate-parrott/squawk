//
//  SQPushOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQPushOnboardingViewController.h"
#import "SQOnboardingViewController.h"

@interface SQPushOnboardingViewController () <UIAlertViewDelegate> {
    IBOutlet UILabel *_textLabel;
    IBOutlet UIButton* _noNotificationsButton;
    IBOutlet UIImageView* _phoneImage;
}

@end

@implementation SQPushOnboardingViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _textLabel.text = NSLocalizedString(@"Squawk is better with notifications. We won't spam you, ever.", @"");
    [self.nextButton setTitle:NSLocalizedString(@"Enable notifications", @"") forState:UIControlStateNormal];
    [_noNotificationsButton setTitle:NSLocalizedString(@"No thanks, no notifications", @"") forState:UIControlStateNormal];
    
    [self rac_liftSelector:@selector(pushStatusChanged:) withSignals:[RACObserve(AppDelegate, pushNotificationsEnabled) skip:1], nil];
}
-(void)pushStatusChanged:(id)_ {
    if ([AppDelegate pushNotificationsEnabled]) {
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
    if ([AppDelegate pushNotificationsEnabled]) {
        [self.owner nextPage];
    } else {
        [AppDelegate setupPushNotifications];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showDenialMessage];
        });
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
-(void)animateOutWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        _textLabel.alpha = 0;
        _noNotificationsButton.alpha = 0;
        
        CGFloat topYOfPhoneImage = [self.view convertPoint:CGPointZero fromView:_phoneImage].y;
        _phoneImage.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height-topYOfPhoneImage+50);
    } completion:^(BOOL finished) {
        
    }];
}

@end
