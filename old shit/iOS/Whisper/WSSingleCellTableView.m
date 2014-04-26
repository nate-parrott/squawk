//
//  WSSingleCellTableView.m
//  Squawk
//
//  Created by Nate Parrott on 2/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSSingleCellTableView.h"

@implementation WSSingleCellTableView

-(void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    self.dataSource = self;
    self.delegate = self;
    self.scrollEnabled = NO;
    [self reloadData];
}
-(int)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UINib nibWithNibName:self.nibName bundle:nil] instantiateWithOwner:nil options:nil][0];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

@end
