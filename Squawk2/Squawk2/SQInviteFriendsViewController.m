//
//  SQInviteFriendsViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 3/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQInviteFriendsViewController.h"
#import "SQTheme.h"
#import "UIViewController+SoftModal.h"
#import "WSContactBoost.h"

@interface SQInviteFriendsViewController ()

@end

@implementation SQInviteFriendsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    for (UIButton* button in @[_sendTextButton, _facebookButton, _twitterButton]) {
        UIImage* image = [button imageForState:UIControlStateNormal];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setImage:image forState:UIControlStateNormal];
        button.tintColor = [SQTheme blue];
    }
    _sendTextButton.enabled = [MFMessageComposeViewController canSendText];
    _facebookButton.enabled = [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
    _twitterButton.enabled = [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
    // localization:
    [_sendTextButton setTitle:NSLocalizedString(@"Text", @"Send an SMS") forState:UIControlStateNormal];
    [_facebookButton setTitle:NSLocalizedString(@"Share", @"Share on Facebook") forState:UIControlStateNormal];
    [_twitterButton setTitle:NSLocalizedString(@"Tweet", @"") forState:UIControlStateNormal];
    [_squawkFeedbackButton setTitle:NSLocalizedString(@"Squawk us feedback", @"").lowercaseString forState:UIControlStateNormal];
}
-(IBAction)postToFacebook:(id)sender {
    SLComposeViewController* composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [composer setInitialText:NSLocalizedString(@"I'm using Squawk to send instant voice messages. Download the iPhone app to squawk with me.", @"")];
    [composer addURL:[NSURL URLWithString:@"http://come.squawkwith.us"]];
    [composer addImage:[UIImage imageNamed:@"fb-icon"]];
    [self presentViewController:composer animated:YES completion:nil];
}
-(IBAction)tweet:(id)sender {
    SLComposeViewController* composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [composer setInitialText:NSLocalizedString(@"I'm using Squawk to send instant voice messages. Download the iPhone app to squawk with me.", @"")];
    [composer addURL:[NSURL URLWithString:@"http://come.squawkwith.us"]];
    [self presentViewController:composer animated:YES completion:nil];
}
-(IBAction)sendText:(id)sender {
    MFMessageComposeViewController* composer = [MFMessageComposeViewController new];
    composer.messageComposeDelegate = self;
    composer.body = NSLocalizedString(@"I'm using Squawk to send instant voice messages. Download the iPhone app to squawk with me. http://come.squawkwith.us", @"");
    [self presentViewController:composer animated:YES completion:nil];
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}
-(IBAction)done:(id)sender {
    [self dismissSoftModal];
}
-(IBAction)openWebsite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://squawkwith.us"]];
}
-(IBAction)squawkFeedback:(id)sender {
    [WSContactBoost boostPhoneNumber:@"00000000001"];
    UIViewController* parent = self.parentViewController;
    [self dismissSoftModal];
    [parent dismissViewControllerAnimated:YES completion:nil];
}

@end
