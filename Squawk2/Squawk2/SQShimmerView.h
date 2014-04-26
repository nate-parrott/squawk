//
//  SQShimmerView.h
//  Squawk2
//
//  Created by Nate Parrott on 3/6/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQShimmerView : UIView {
    NSTimer* _shimmerTimer;
}

@property(nonatomic)BOOL shimmering;

@end
