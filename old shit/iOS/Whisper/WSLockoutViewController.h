//
//  WSLockoutViewController.h
//  Squawk
//
//  Created by Nate Parrott on 2/12/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSLockoutViewController : UIViewController {
    IBOutlet UILabel* _label;
    IBOutlet UIButton* _actionButton;
}

-(IBAction)tappedActionButton:(id)sender;

@end
