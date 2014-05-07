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
    
    NSMutableArray* _circularViews;
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
            self.nextButton.enabled = YES;
        } else {
            self.nextButton.backgroundColor = [SQTheme red];
            [self.nextButton setTitle:NSLocalizedString(@"Verify my phone number", @"") forState:UIControlStateNormal];
            self.nextButton.enabled = (self.loginState ==  SQLoginNotStarted);
        }
    }];
    RAC(self.instructionsLabel, text) = [[RACSignal combineLatest:@[RACObserve(self, loginState), RACObserve(self, secret)]] map:^id(id value) {
        if (self.loginState == SQLoginNotStarted) {
            return NSLocalizedString(@"Squawk is the quickest way to send a voice message. To sign up, all you need is a phone number.", @"");
        } else if (self.loginState == SQLoginAskingUserToSendVerification) {
            return [NSString stringWithFormat:NSLocalizedString(@"Text '%@' to '%@' from your phone.", @"Text [code] to [phone number] from your phone."), self.secret, VERIFICATION_NUMBER];
        } else {
            return @"";
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
        _messageComposer.body = [NSString stringWithFormat:NSLocalizedString(@"Just hit send \n[we need to verify your phone number]\n %@", @""), self.secret];
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
#pragma mark Transitioning

-(void)animateInWithDuration:(NSTimeInterval)duration {
    if (!_circularViews) {
        _circularViews = [NSMutableArray new];
        NSArray* colors = @[[UIColor colorWithRed:0.973 green:0.835 blue:0.435 alpha:1.000],
                            [UIColor colorWithRed:0.965 green:0.690 blue:0.357 alpha:1.000],
                            [UIColor colorWithRed:0.965 green:0.557 blue:0.329 alpha:1.000]];
        self.backgroundColor = colors.firstObject;
        int i = 0;
        for (UIColor* color in colors) {
            UIView* colorView = [UIView new];
            colorView.backgroundColor = color;
            colorView.bounds = CGRectMake(0, 0, 2, 2);
            colorView.layer.cornerRadius = 1;
            colorView.center = self.parrot.center;
            CGFloat radius = sqrtf(powf(colorView.center.x-self.view.bounds.size.width, 2) + powf(colorView.center.y-self.view.bounds.size.height, 2));
            if (i == 1) {
                radius = radius*0.4;
            } else if (i == 2) {
                radius = radius*0.28;
            }
            
            [self.view insertSubview:colorView atIndex:i];
            [UIView animateWithDuration:duration/2 delay:0*duration/2*i/(float)colors.count*0.7 options:0 animations:^{
                colorView.transform = CGAffineTransformMakeScale(radius, radius);
            } completion:^(BOOL finished) {
                
            }];
            i++;
            
            [_circularViews addObject:colorView];
        }
    }
    self.parrot.transform = CGAffineTransformMakeTranslation(0, -self.parrot.frame.size.height);
    [UIView animateWithDuration:duration*0.7 delay:duration*0.3 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
        self.parrot.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    self.nameLabel.alpha = 0;
    self.instructionsLabel.alpha = 0;
    [UIView animateWithDuration:duration*0.6 delay:duration*0.6 options:0 animations:^{
        self.nameLabel.alpha = 1;
        self.instructionsLabel.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}
-(void)animateOutWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        for (int i=1; i<_circularViews.count; i++) {
            UIView* v = _circularViews[i];
            v.transform = CGAffineTransformMakeScale(100, 100);
        }
    }];
}

@end
