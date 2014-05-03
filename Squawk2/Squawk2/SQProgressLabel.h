//
//  SQProgressLabel.h
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQProgressLabel : UIView

@property(nonatomic)CGSize fill;
@property(strong,readonly)UILabel* label;

-(void)flashAndUnfill;

@end