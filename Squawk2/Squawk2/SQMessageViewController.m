//
//  SQMessageViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 3/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQMessageViewController.h"

@interface SQMessageViewController ()

@end

@implementation SQMessageViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _done.enabled = !!self.message[@"presentation_key"];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.message[@"show_url"]]]];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}
-(IBAction)close:(id)sender {
    if (self.message[@"presentation_key"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:self.message[@"presentation_key"]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
