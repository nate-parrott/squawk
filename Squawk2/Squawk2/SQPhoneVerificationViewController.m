//
//  SQPhoneVerificationViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQPhoneVerificationViewController.h"
#import "NSString+RandomString.h"
#import "SQAPI.h"
#import "SQTheme.h"
#import "SQOnboardingViewController.h"

#define MAX_LOGIN_TRIES 7

typedef enum {
    SQLoginNotStarted = 0,
    SQLoginSendingVerificationText = 1,
    SQLoginAskingUserToSendVerification = 2,
    SQLoginCheckingForVerification
} SQLoginState;

@interface SQPhoneVerificationViewController () {
    int _numLoginTries;
    MFMessageComposeViewController* _messageComposer;
}

@property(strong)NSString* secret;
@property(nonatomic)SQLoginState loginState;
@property(strong)NSString* errorMessage;

@end

@implementation SQPhoneVerificationViewController

#define CAN_SEND_TEXT [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]

#pragma mark View bindings
-(void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_IPHONE_SIMULATOR
    self.secret = [NSString randomStringOfLength:3 insertDashes:YES];
#else
    self.secret = [NSString randomStringOfLength:12 insertDashes:YES];
#endif
    
    [RACObserve(self, loginState) subscribeNext:^(id x) {
        if (self.loginState == SQLoginAskingUserToSendVerification) {
            self.nextButton.backgroundColor = [SQTheme red];
            [self.nextButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        } else {
            self.nextButton.backgroundColor = [SQTheme red];
            [self.nextButton setTitle:NSLocalizedString(@"Verify my phone number", @"") forState:UIControlStateNormal];
            self.nextButton.enabled = (self.loginState ==  SQLoginNotStarted);
        }
    }];
    RAC(self.instructionsLabel, text) = [[RACSignal combineLatest:@[RACObserve(self, loginState), RACObserve(self, secret)]] map:^id(id value) {
        if (self.loginState == SQLoginNotStarted) {
            return NSLocalizedString(@"Squawk is the quickest way to send a voice message. To sign up, all you need is a phone number.", @"");
        } else {
            return [NSString stringWithFormat:NSLocalizedString(@"Text '%@' to '%@' from your phone.", @"Text [code] to [phone number] from your phone."), self.secret, VERIFICATION_NUMBER];
        }
    }];
    [RACObserve(self, loginState) subscribeNext:^(id x) {
        if (self.loginState == SQLoginAskingUserToSendVerification) {
            if (CAN_SEND_TEXT) {
                self.instructionsLabel.hidden = YES;
                // delay the visibility a little:
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.instructionsLabel.hidden = NO;
                });
            } else {
                self.instructionsLabel.hidden = NO;
            }
        }
    }];
    RAC(self.errorLabel, text) = RACObserve(self, errorMessage);
    RAC(self.loadingView, shimmering) = [RACObserve(self, loginState) map:^id(id value) {
        return @([value integerValue] == SQLoginCheckingForVerification);
    }];
}
#pragma mark Actions
-(IBAction)pressedButton:(id)sender {
    //[self.owner nextPage];
    //return;
    
    if (self.loginState == SQLoginNotStarted) {
        [self sendVerificationText:nil];
    } else if (self.loginState == SQLoginAskingUserToSendVerification) {
        [self tryLogin:nil];
    }
}
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
    [_messageComposer dismissViewControllerAnimated:YES completion:nil];
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
            dispatch_async(dispatch_get_main_queue(), ^{
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
            });
        }];
    }
}

-(void)loggedIn {
    [self.owner nextPage];
    [SQAPI call:@"/notify_friends" args:@{} callback:^(NSDictionary *result, NSError *error) {
        
    }];
}

-(void)encounteredError:(NSString*)message {
    self.errorMessage = message;
    self.loginState = SQLoginNotStarted;
}

@end
