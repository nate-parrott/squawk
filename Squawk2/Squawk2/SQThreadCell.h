//
//  SQThreadCell.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQThread.h"
#import "WSConcentricCirclesViewAdvancedHD2014.h"

@class SQMainViewController;

NSString *const SQCheckmarkVisibleNextToThreadIdentifier;

@interface SQThreadCell : UITableViewCell <UIGestureRecognizerDelegate> {
    BOOL _setup;
    IBOutlet UILabel* _label;
    
    IBOutlet UIButton* _button;
    IBOutlet UILabel* _unreadCount;
}

@property(strong,nonatomic)SQThread* thread;
@property(weak)SQMainViewController* controller;

@property(strong)IBOutlet UILongPressGestureRecognizer* gestureRec;
-(IBAction)pressed:(id)sender;

-(void)scrolled;

@end
