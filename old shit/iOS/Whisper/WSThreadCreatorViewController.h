//
//  WSThreadCreatorViewController.h
//  Squawk
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSThreadCreatorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSArray* _senders;
    NSMutableSet* _selectedPhoneNumbers;
    IBOutlet UIActivityIndicatorView* _loader;
    
    IBOutlet UITextField* _addNameField;
    IBOutlet UITextField* _Field;
    IBOutlet UIButton* _addPhoneButton;
}

@property(strong)IBOutlet UITableView* tableView;

-(IBAction)makeThread:(id)sender;
-(IBAction)dismiss:(id)sender;

@property BOOL working;

-(IBAction)addPhoneNumber:(id)sender;

@end
