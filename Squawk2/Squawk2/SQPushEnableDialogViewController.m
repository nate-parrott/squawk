//
//  SQPushEnableDialogViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQPushEnableDialogViewController.h"
#import "UIViewController+SoftModal.h"

@interface SQPushEnableDialogViewController () {
    IBOutlet UILabel* _title;
    IBOutlet UILabel* _text;
}

@end

@implementation SQPushEnableDialogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppDelegate setupPushNotifications];
    
    [_closeButton setTitle:NSLocalizedString(@"Close", @"") forState:UIControlStateNormal];
    _title.text = NSLocalizedString(@"Turn on notifications", @"");
    _text.text = NSLocalizedString(@"Squawk is better with notifications.\n\nIf you've said 'no' to notifications for Squawk before, you may need to turn them on in the Settings app.\n\nGo to Settings → Notification Center → Squawk, and turn on all the notification types you'd like.", @"");
    
    RACSignal* gotAccess = [RACObserve(AppDelegate, pushNotificationsEnabled) filter:^BOOL(id value) {
        return [value boolValue];
    }];
    [self rac_liftSelector:@selector(close:) withSignals:gotAccess, nil];
}
-(IBAction)close:(id)sender {
    [self dismissSoftModal];
}

@end
