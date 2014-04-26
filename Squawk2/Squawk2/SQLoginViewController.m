//
//  SQLoginViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQLoginViewController.h"
#import "NSString+RandomString.h"
#import "SQAPI.h"


@interface SQLoginViewController ()

@end

@implementation SQLoginViewController

#define CAN_SEND_TEXT [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]

#pragma mark View bindings
-(void)viewDidLoad {
    [super viewDidLoad];
    self.secret = [NSString randomStringOfLength:12 insertDashes:YES];
    RAC(_sendVerificationButton, enabled) = [RACObserve(self, loginState) map:^id(id value) {
        return @([value integerValue] == SQLoginNotStarted);
    }];
    RAC(_doneSendingVerificationButton, hidden) = [[RACObserve(self, loginState) map:^id(id value) {
        return @([value integerValue] == SQLoginAskingUserToSendVerification);
    }] not];
    RAC(_textLabel, text) = [RACObserve(self, secret) map:^id(id value) {
        return [NSString stringWithFormat:NSLocalizedString(@"Text '%@' to '%@'", @"Text [code] to [phone number]"), value, VERIFICATION_NUMBER];
    }];
    [RACObserve(self, loginState) subscribeNext:^(id x) {
        if (self.loginState == SQLoginNotStarted) {
            _textLabel.hidden = YES;
        } else {
            if (CAN_SEND_TEXT) {
                // delay the visibility a little:
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _textLabel.hidden = NO;
                });
            } else {
                _textLabel.hidden = NO;
            }
        }
    }];
    RAC(_errorLabel, text) = RACObserve(self, errorMessage);
    RAC(_loadingIndicator, shimmering) = [RACObserve(self, loginState) map:^id(id value) {
        return @([value integerValue] == SQLoginCheckingForVerification);
    }];
    
    // localization:
    [_sendVerificationButton setTitle:NSLocalizedString(@"Verify my phone number", @"") forState:UIControlStateNormal];
    [_doneSendingVerificationButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    _letsGetStarted.text = NSLocalizedString(@"Let's get started", @"").lowercaseString;
}
#pragma mark Actions
-(IBAction)sendVerificationText:(id)sender {
    self.errorMessage = nil;
    if (CAN_SEND_TEXT) {
        _messageComposer = [[MFMessageComposeViewController alloc] init];
        _messageComposer.messageComposeDelegate = self;
        _messageComposer.recipients = @[VERIFICATION_NUMBER];
        _messageComposer.body = [NSString stringWithFormat:NSLocalizedString(@"Just hit send [we need to verify your phone number]\n %@", @""), self.secret];
        [self presentViewController:_messageComposer animated:YES completion:nil];
        self.loginState = SQLoginSendingVerificationText;
    } else {
        self.loginState = SQLoginAskingUserToSendVerification;
    }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    if (result==MessageComposeResultSent) {
        [self tryLogin:nil];
    } else if (result == MessageComposeResultFailed) {
        [self encounteredError:NSLocalizedString(@"Failed to send text.", @"")];
    } else {
        self.loginState = SQLoginAskingUserToSendVerification;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)tryLogin:(id)sender {
    _numLoginTries = 0;
    self.loginState = SQLoginCheckingForVerification;
    [self tryLogin];
}
-(void)tryLogin {
    if (self.loginState != SQLoginCheckingForVerification) return;
    if (_numLoginTries++ > MAX_LOGIN_TRIES) {
        [self encounteredError:NSLocalizedString(@"We didn't receive your text.", @"")];
    } else {
        [SQAPI logInWithSecret:self.secret callback:^(BOOL success, NSError *error) {
            if (success) {
                [self loggedIn];
            } else {
                if ([error.domain isEqualToString:SQErrorDomain] && error.code == SQLoginBadSecretError) {
                    // maybe the text hasn't come in yet. try again a little later:
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self tryLogin];
                    });
                } else {
                    [self encounteredError:NSLocalizedString(@"We couldn't connect to the Squawk cloud. Try again later.", @"")];
                }
            }
        }];
    }
}

-(void)loggedIn {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [SQAPI call:@"/notify_friends" args:@{} callback:^(NSDictionary *result, NSError *error) {
        
    }];
}

-(void)encounteredError:(NSString*)message {
    self.errorMessage = message;
    self.loginState = SQLoginNotStarted;
}

@end
