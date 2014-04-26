//
//  WSSettingsViewController.m
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSSettingsViewController.h"
#import "WSAppDelegate.h"
#import "SKActionPrompt.h"
#import "NPAddressBook.h"
#import "WSContactBoost.h"
#import <Helpshift.h>
#import "WSEarSensor.h"


@interface WSSettingsViewController ()

@end

@implementation WSSettingsViewController

#pragma mark View methods
-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.941 green:0.227 blue:0.278 alpha:1.000];
    [self createBindings];
}
-(IBAction)dismiss:(id)sender {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveData];
}
#pragma mark Data
-(void)createBindings {
    RAC(_multisquawkEnabled, on) = [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:WSMultisquawkEnabled observer:self];
    RAC(_raiseToSquawkEnabled, on) = [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:WSRaiseToSquawkEnabled observer:self];
}
-(void)loadData {
    _phone.text = [[PFUser currentUser] valueForKey:@"username"];
    _nickname.text = [[PFUser currentUser] valueForKey:@"nickname"];
    
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    _appInfo.text = [NSString stringWithFormat:@"Squawk %@ (%@, %s)", version, build, __DATE__];
    
    _raiseToSquawkBlocker.hidden = [WSEarSensor shared].isAvailable;
}
-(void)saveData {
    if (![[[PFUser currentUser] valueForKey:@"nickname"] isEqualToString:_nickname.text] && _nickname.text.length) {
        [[PFUser currentUser] setValue:_nickname.text forKey:@"nickname"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Save Error" message:@"We couldn't connect to the cloud to save your settings. Please try again later." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        }];
    }
}
#pragma mark Actions
-(IBAction)signOut:(id)sender {
    SKActionPrompt* prompt = [[SKActionPrompt alloc] initWithTitle:@"Sign out?"];
    [prompt addDestructiveButtonWithTitle:@"Yes, sign out" callback:^{
        [self dismiss:nil];
        [AppDelegate logOut];
    }];
    [prompt presentFromRect:[sender bounds] inView:sender];
}
-(IBAction)addContact:(id)sender {
    if (_addContactPhone.text.length) {
        [NPAddressBook createContactWithName:_addContactName.text phone:_addContactPhone.text info:nil callback:^{
            [WSContactBoost boostPhoneNumber:_addContactPhone.text];
            [self dismiss:nil];
        }];
    }
}
-(IBAction)multisquawkSettingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:WSMultisquawkEnabled];
}
-(IBAction)raiseToSquawkSettingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:WSRaiseToSquawkEnabled];
}
-(IBAction)showFAQs:(id)sender {
    [[Helpshift sharedInstance] showFAQs:self withOptions:nil];
}
-(IBAction)showFeedback:(id)sender {
    [[Helpshift sharedInstance] showConversation:self withOptions:nil];
}

@end
