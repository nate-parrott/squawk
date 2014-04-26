//
//  WSSettingsViewController.h
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSSettingsViewController : UITableViewController {
    IBOutlet UITextField *_phone, *_nickname;
    
    IBOutlet UITextField *_addContactName, *_addContactPhone;
    
    IBOutlet UISwitch* _multisquawkEnabled;
    
    IBOutlet UISwitch* _raiseToSquawkEnabled;
    IBOutlet UIView* _raiseToSquawkBlocker;
    
    IBOutlet UILabel* _appInfo;
}

-(IBAction)dismiss:(id)sender;

-(IBAction)signOut:(id)sender;

-(IBAction)addContact:(id)sender;

-(IBAction)multisquawkSettingChanged:(id)sender;

-(IBAction)raiseToSquawkSettingChanged:(id)sender;

-(IBAction)showFAQs:(id)sender;
-(IBAction)showFeedback:(id)sender;

@end
