//
//  SQThreadMakerViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQThread.h"

@interface SQThreadMakerViewController : UIViewController <UITextFieldDelegate>

@property(strong)NSArray* threads;
-(IBAction)dismiss:(id)sender;
-(IBAction)createThread:(id)sender;
-(IBAction)addContact:(id)sender;

-(IBAction)inviteFriends:(id)sender;

+(NSMutableDictionary*)prepopulationDict;
/*
 this is used to pre-populate the entry fields; e.g. in response to a launch via url scheme
 the keys are 'phone' and 'name'
 */

@end
