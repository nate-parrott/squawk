//
//  SQProgressLabel.m
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQProgressLabel.h"
#import "SQTheme.h"

@interface SQProgressLabel () {
    UIView* _fillView;
}

@end

@implementation SQProgressLabel

-(void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor grayColor];
    _fillView = [UIView new];
    _fillView.backgroundColor = [SQTheme blue];
    [self addSubview:_fillView];
    
    _label = [UILabel new];
    _label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:14];
    [self.layer setMask:_label.layer];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
    _fillView.frame = CGRectMake(0, self.bounds.size.height*(1-self.fill.height), self.bounds.size.width*self.fill.width, self.bounds.size.height*self.fill.height);
}
-(CGSize)intrinsicContentSize {
    return [self.label intrinsicContentSize];
}
-(void)setFill:(CGSize)fill {
    _fill = fill;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
-(void)flashAndUnfill {
    self.fill = CGSizeZero;
    self.backgroundColor = [UIColor blackColor];
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{
        self.backgroundColor = [UIColor whiteColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseOut animations:^{
            self.backgroundColor = [UIColor grayColor];
        } completion:^(BOOL finished) {
            
        }];
    }];
}

@end
