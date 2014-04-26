//
//  WSWelcomeViewController.m
//  Whisper
//
//  Created by Nate Parrott on 1/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSWelcomeViewController.h"
#import "NPContact.h"
#import "WSMainViewController.h"
#import "NSString+RandomString.h"
#import "WSAppDelegate.h"

#define NICKNAME_PLACEHOLDER NSLocalizedString(@"pick a nickname", @"")

#define VERIFY_NUM @"646-576-7688"

#define CAN_SEND_TEXT [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]

@interface WSWelcomeViewController ()

@end

@implementation WSWelcomeViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _useYourVoiceLabel.text = NSLocalizedString(@"use your voice", @"");
    [_startButton setTitle:NSLocalizedString(@"get started", @"") forState:UIControlStateNormal];
    
    _nicknameField.text = NICKNAME_PLACEHOLDER;
    
    if (!_password) {
        _password = [NSString randomStringOfLength:12 insertDashes:YES].lowercaseString;
    }
    _nicknameField.text = NICKNAME_PLACEHOLDER;
    
    _nicknameField.background = [[UIImage imageNamed:@"roundrect"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_nicknameField becomeFirstResponder];
}

-(void)setWorking:(BOOL)working {
    _working = working;
    _nicknameField.enabled = !_working;
    if (working) {
        [_loader startAnimating];
    } else {
        [_loader stopAnimating];
    }
    _startButton.enabled = !_working;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self verify:nil];
    [_nicknameField resignFirstResponder];
    return YES;
}
-(IBAction)verify:(id)sender {
    self.working = YES;
    if (CAN_SEND_TEXT && [MFMessageComposeViewController canSendText]) {
        _messageSender = [MFMessageComposeViewController new];
        _messageSender.body = [NSString stringWithFormat:NSLocalizedString(@"Just hit 'send.'\n\n[We need to verify your phone number] %@", @"'%@' must come at the end"), _password];
        _messageSender.recipients = @[VERIFY_NUM];
        _messageSender.messageComposeDelegate = (id)self;
        [self presentViewController:_messageSender animated:YES completion:nil];
    } else {
        self.working = NO;
        _checkButton.hidden = NO;
        NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"Text %@ to %@ from your phone.", @""), _password, VERIFY_NUM];
        _verificationInstructionsLabel.text = msg;
        _verificationInstructionsLabel.hidden = NO;
        //[[[UIAlertView alloc] initWithTitle:@"Verify Phone Number" message:msg delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil] show];
    }
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    if (result == MessageComposeResultSent && !_polling) {
        self.working = YES;
        _polling = YES;
        _tryLoginCount = 0;
        [self poll];
    } else {
        self.working = NO;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _polling = NO;
}
-(NSString*)nickname {
    NSString* name = _nicknameField.text;
    if ([name isEqualToString:NICKNAME_PLACEHOLDER]) {
        name = nil;
    }
    if (!name.length) {
        name = [[PFUser currentUser] valueForKey:@"username"];
    }
    return name;
}
-(void)poll {
    if (_polling) {
        if (_tryLoginCount++ > 20) {
            [self gotError:nil];
            return;
        }
        [self tryLogin:^(PFUser* user, NSError* error) {
            if (user) {
                [self done];
            } else {
                if (error) {
                    [self gotError:error];
                } else {
                    [self performSelector:@selector(poll) withObject:nil afterDelay:1.0];
                }
            }
        }];
    }
}
-(IBAction)check:(id)sender {
    self.working = YES;
    [self tryLogin:^(PFUser* user, NSError* error) {
        self.working = NO;
        if (user) {
            [self done];
        } else {
            if (error) {
                [self gotError:error];
            } else {
                [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"We haven't received your verification message yet.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", @"") otherButtonTitles:nil] show];
            }
        }
    }];
}
-(void)gotError:(NSError*)error {
    _polling = NO;
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert title") message:NSLocalizedString(@"We couldn't contact to the Squawk cloud. Make sure you're connected to the Internet.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", @"") otherButtonTitles:nil] show];
    self.working = NO;
}
-(void)tryLogin:(void(^)(PFUser* user, NSError* error))block {
    [PFCloud callFunctionInBackground:@"lookupUsernameByPassword" withParameters:@{@"password": _password} block:^(id object, NSError *error) {
        if (object && [object isKindOfClass:[NSString class]]) {
            [PFUser logInWithUsernameInBackground:object password:_password block:^(PFUser *user, NSError *error) {
                if (![[user valueForKey:@"installations"] containsObject:[PFInstallation currentInstallation]]) {
                    [user addObject:[PFInstallation currentInstallation] forKey:@"installations"];
                }
                [user setValue:[self nickname] forKey:@"nickname"];
                [user saveInBackground];
                [PFCloud callFunctionInBackground:@"joined" withParameters:@{@"nickname": [self nickname]} block:^(id object, NSError *error) {}];
                [PFCloud callFunctionInBackground:@"sendWelcome" withParameters:@{} block:^(id object, NSError *error) {
                    if (!error) {
                        [[NSUserDefaults standardUserDefaults] setValue:[self nickname] forKey:@"Nickname"];
                        block(user, nil);
                    } else {
                        block(nil, error);
                    }
                }];
            }];
        } else {
            block(nil, error);
        }
    }];
}
-(void)done {
    [AppDelegate trackEventWithCategory:@"ui_action" action:@"successful_sign_up" label:nil value:nil];
    self.working = NO;
    [AppDelegate setCurrentUser:[PFUser currentUser]];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
