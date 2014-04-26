//
//  SQMessageViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 3/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQMessageViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView* _webView;
    IBOutlet UIBarButtonItem* _done;
}

@property(strong)NSDictionary* message;

@end
