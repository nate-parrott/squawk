//
//  WSAboutViewController.m
//  Squawk
//
//  Created by Nate Parrott on 3/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSAboutViewController.h"

@interface WSAboutViewController ()

@end

@implementation WSAboutViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [_webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"about"]]];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType==UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

@end
