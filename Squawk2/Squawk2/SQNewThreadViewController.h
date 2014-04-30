//
//  SQNewThreadViewController.h
//  Squawk2
//
//  Created by Nate Parrott on 4/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQNewThreadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property(strong,nonatomic)NSArray* squawkers;

@property(weak)IBOutlet UITableView* tableView;

+(NSMutableDictionary*)prepopulationDict;

@end
