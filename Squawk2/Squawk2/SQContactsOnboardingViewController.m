//
//  SQContactsOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQContactsOnboardingViewController.h"
#import "SQOnboardingViewController.h"
#import "NPAddressBook.h"

@interface SQContactsOnboardingViewController () {
    IBOutlet UILabel* _text;
}

@end

@implementation SQContactsOnboardingViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.nextButton setTitle:NSLocalizedString(@"Allow access to contacts", @"") forState:UIControlStateNormal];
    _text.text = NSLocalizedString(@"Squawk uses your contacts, so you don't need to manage a separate friends list.", @"");
}
-(IBAction)done:(id)sender {
    [NPAddressBook getAuthorizedAddressBookWithCallback:^(NPAddressBook *book) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (book) {
                [NPAddressBook startPopulatingContactsSignal];
                [self.owner nextPage];
            } else {
                [self showMessage:NSLocalizedString(@"You can give Squawk access to your contacts in the Settings app, under Privacy.", @"") title:NSLocalizedString(@"Squawk can't see your contacts", @"")];
            }
        });
    }];
}

@end
