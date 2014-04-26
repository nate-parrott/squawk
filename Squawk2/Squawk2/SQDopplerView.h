//
//  SQDopplerView.h
//  SQScratch
//
//  Created by Nate Parrott on 3/14/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQDopplerView : UIView

@property float outgoingSpeed; // can be negative
@property int numViews;

@property(nonatomic)BOOL animating;

@end
