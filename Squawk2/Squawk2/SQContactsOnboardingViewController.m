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

@interface SQContactsOnboardingViewController ()

@end

@implementation SQContactsOnboardingViewController

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
