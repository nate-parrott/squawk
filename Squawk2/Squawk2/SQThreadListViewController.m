//
//  SQThreadListViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 5/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQThreadListViewController.h"
#import "SQThread.h"

@interface SQThreadListViewController () <UITableViewDataSource, UITableViewDelegate>

@property(strong)IBOutlet UITableView* tableView;
@property(strong)IBOutlet UILabel* titleLabel;

@end

@implementation SQThreadListViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = NSLocalizedString(@"People in this thread", @"");
}
-(int)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.threadMembers.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* number = self.threadMembers[indexPath.row];
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    UILabel* label = (id)[cell viewWithTag:1];
    label.text = [SQThread nameForNumber:number];
    return cell;
}

@end
