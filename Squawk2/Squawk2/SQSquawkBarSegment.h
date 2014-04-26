//
//  SQSquawkBarSegment.h
//  Squawk2
//
//  Created by Nate Parrott on 4/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQSquawkBarSegment : UIView

@property(strong)UILabel* label;
@property(strong)UIView* backgroundView;
@property UIEdgeInsets labelInsets;
@property UIEdgeInsets backgroundInsets;

@end
