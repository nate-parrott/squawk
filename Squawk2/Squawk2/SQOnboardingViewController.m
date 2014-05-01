//
//  SQOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQOnboardingViewController.h"
#import "SQOnboardingPage.h"

@interface SQOnboardingViewController ()

@property(strong)NSString* currentPageIdentifier;

@end

@implementation SQOnboardingViewController

#pragma mark Paging
-(NSArray*)pageIdentifiers {
    // storyboard identifiers for each page:
    return @[@"Phone", @"Contacts", @"Microphone", @"Push"];
}
-(void)nextPage {
    int currentIndex = -1;
    if (self.currentPageIdentifier) {
        currentIndex = [[self pageIdentifiers] indexOfObject:self.currentPageIdentifier];
    }
    int newIndex = currentIndex+1;
    if (newIndex < [self pageIdentifiers].count) {
        if (self.currentPage) {
            [self.currentPage viewWillDisappear:YES];
            [self.currentPage.view removeFromSuperview];
            [self.currentPage viewDidDisappear:YES];
            [self.currentPage removeFromParentViewController];
        }
        self.currentPageIdentifier = [self pageIdentifiers][newIndex];
        self.currentPage = [self.storyboard instantiateViewControllerWithIdentifier:self.currentPageIdentifier];
        self.currentPage.owner = self;
        [self addChildViewController:self.currentPage];
        [self.currentPage viewWillAppear:YES];
        [self.view addSubview:self.currentPage.view];
        [self.currentPage viewDidAppear:YES];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
#pragma mark Views
-(void)viewDidLoad {
    [super viewDidLoad];
    [self nextPage];
}
-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.currentPage.view.frame = self.view.bounds;
}

@end
