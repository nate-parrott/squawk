//
//  WSThreadCreatorViewController.m
//  Squawk
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSThreadCreatorViewController.h"
#import "WSMainViewController.h"

@interface WSThreadCreatorViewController ()

@end

@implementation WSThreadCreatorViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.973 green:0.557 blue:0.302 alpha:1.000];
    
    _selectedPhoneNumbers = [NSMutableSet new];
    _senders = [[WSMainViewController  mostRecentSendersOrError] first];
    if (![_senders isKindOfClass:[NSArray class]]) _senders = nil;
    _senders = [_senders.rac_sequence filter:^BOOL(id value) {
        return ![value isGroupThread] && [value preferredPhoneNumber];
    }].array;
    RAC(_loader, hidden) = [RACObserve(self, working) not];
}
#pragma mark Tableview
-(int)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _senders.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    WSMessageSender* sender = _senders[indexPath.row];
    cell.textLabel.text = sender.displayName;
    cell.detailTextLabel.text = sender.nickname;
    cell.accessoryType = [_selectedPhoneNumbers containsObject:sender.preferredPhoneNumber]? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WSMessageSender* sender = _senders[indexPath.row];
    if ([_selectedPhoneNumbers containsObject:sender.preferredPhoneNumber]) {
        [_selectedPhoneNumbers removeObject:sender.preferredPhoneNumber];
    } else {
        [_selectedPhoneNumbers addObject:sender.preferredPhoneNumber];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(IBAction)makeThread:(id)sender {
    self.working = YES;
    [WSThreadCreatorViewController createThreadFromPhoneNumbers:_selectedPhoneNumbers.allObjects callback:^id(id initialMessage){
        self.working = NO;
        if (initialMessage) {
            [self dismiss:nil];
        }
        return nil;
    }];
}
-(IBAction)dismiss:(id)sender {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
+(void)createThreadFromPhoneNumbers:(NSArray*)phones callback:(WSGenericCallback)callback {
    [PFCloud callFunctionInBackground:@"getUsersByPhone" withParameters:@{@"phoneNumbers": phones} block:^(id users, NSError *error) {
        if (error) {
            callback(nil);
        } else {
            PFObject* thread = [PFObject objectWithClassName:@"Message" dictionary:@{@"threadMembers": users, @"recipient": [PFUser currentUser], @"sender": [PFUser currentUser]}];
            [thread saveInBackground];
            callback(thread);
        }
    }];
}

@end
