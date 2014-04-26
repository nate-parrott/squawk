//
//  IPadWelcomeViewController.h
//  Squawk
//
//  Created by Justin Brower on 1/26/14.
//  Copyright (c) 2014 Justin Brower. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPContact.h"

@interface IPadWelcomeViewController : UIViewController


@property (strong) IBOutlet UIButton *getSquawkin;
@property (strong) IBOutlet UITextField *input;

@property (strong) UIScrollView *scrollView;
@property (strong) UIView *realView;
@end
