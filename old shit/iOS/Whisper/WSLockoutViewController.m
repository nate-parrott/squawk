//
//  WSLockoutViewController.m
//  Squawk
//
//  Created by Nate Parrott on 2/12/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSLockoutViewController.h"
#import <ReactiveCocoa.h>
#import "WSAppDelegate.h"

@interface WSLockoutViewController ()

@end

@implementation WSLockoutViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    RAC(_label, text) = [[AppDelegate globalProperties] map:^id(NSDictionary* props) {
        return props[@"lockoutMessage1"];
    }];
    [[[AppDelegate globalProperties] map:^id(NSDictionary* props) {
        return props[@"lockoutURL1"];
    }] subscribeNext:^(id x) {
        [_actionButton setTitle:x forState:UIControlStateNormal];
    }];
}
-(IBAction)tappedActionButton:(id)sender {
    NSDictionary* props = [[AppDelegate globalProperties] first];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:props[@"lockoutURL1"]]];
}

@end
