//
//  WSSingleCellTableView.h
//  Squawk
//
//  Created by Nate Parrott on 2/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSSingleCellTableView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property(strong)NSString* nibName;

@end
