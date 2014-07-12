//
//  SQGalleryView.h
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQGalleryView : UIView

-(void)removeViewAtIndex:(int)index;

@property (nonatomic,weak) IBOutlet UIView *nextHintChevron;

@end
