//
//  SQCheckmarkSegment.h
//  Squawk2
//
//  Created by Nate Parrott on 4/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQSquawkBarSegment.h"

@interface SQCheckmarkSegment : SQSquawkBarSegment

@property(nonatomic)CGFloat pullProgress;
-(void)animateSendingCheckmark:(void(^)())completion;
@property(strong)UIImageView *lightCheck, *darkCheck;

@property BOOL animationInProgress;
@property BOOL waitingForReset;

@end
