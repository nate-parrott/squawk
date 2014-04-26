//
//  WSAboutViewController.h
//  Squawk
//
//  Created by Nate Parrott on 3/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSAboutViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView* _webView;
}

@end
