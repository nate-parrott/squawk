//
//  SQSquawkBarSegment.m
//  Squawk2
//
//  Created by Nate Parrott on 4/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQSquawkBarSegment.h"

@implementation SQSquawkBarSegment

-(id)init {
    self = [super init];
    self.backgroundView = [UIView new];
    [self addSubview:self.backgroundView];
    self.label = [UILabel new];
    [self addSubview:self.label];
    return self;
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = UIEdgeInsetsInsetRect(self.bounds, self.labelInsets);
    self.backgroundView.transform = CGAffineTransformIdentity;
    self.backgroundView.frame = UIEdgeInsetsInsetRect(self.bounds, self.backgroundInsets);
    CGFloat skew = -0.2;
    // thanks http://stackoverflow.com/questions/18770721/skewing-a-uiimageview-using-cgaffinetransform
    self.backgroundView.transform = CGAffineTransformMake(1.f, 0.f, skew, 1.f, 0.f, 0.f);
}

@end
