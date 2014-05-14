//
//  SQStripedIndicator.m
//  Scratch3
//
//  Created by Nate Parrott on 5/13/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQStripedIndicator.h"

@interface SQStripedIndicator () {
    NSMutableArray* _stripes;
}

@end

@implementation SQStripedIndicator

-(void)setHighlightPoints:(NSArray *)highlightPoints {
    _highlightPoints = highlightPoints;
    [self updateStripeColoring];
}
-(void)updateStripeColoring {
    int numHighlightPoints = self.highlightPoints.count;
    CGFloat* highlightPoints = malloc(sizeof(CGFloat)*numHighlightPoints);
    for (int i=0; i<numHighlightPoints; i++) highlightPoints[i] = [_highlightPoints[i] floatValue];
    
    int i = 0;
    for (UIView* stripe in _stripes) {
        CGFloat x = i*1.0/_stripes.count;
        int pointsBefore = 0;
        while (pointsBefore < numHighlightPoints && x >= highlightPoints[pointsBefore]) {
            pointsBefore++;
        }
        BOOL highlighted = (pointsBefore%2)==1;
        stripe.alpha = highlighted? 1 : 0.5;
        stripe.backgroundColor = [UIColor whiteColor];
        i++;
    }
    
    if (highlightPoints) free(highlightPoints);
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    if (_stripes.count != [self numberOfStripesForWidth]) {
        for (UIView* stripe in _stripes) [stripe removeFromSuperview];
        if (!_stripes) _stripes = [NSMutableArray new];
        int numStripes = [self numberOfStripesForWidth];
        for (int i=0; i<numStripes; i++) {
            UIView* stripe = [UIView new];
            [self addSubview:stripe];
            [_stripes addObject:stripe];
        }
        [self updateStripeColoring];
    }
    CGFloat width = [self stripeWidth] * _stripes.count;
    CGFloat x = (self.bounds.size.width-width)/2;
    for (UIView* stripe in _stripes) {
        stripe.frame = CGRectInset(CGRectMake(x, 0, [self stripeWidth], self.bounds.size.height), 4, 8);
        x += [self stripeWidth];
    }
}
-(CGFloat)stripeWidth {
    return 9;
}
-(CGFloat)numberOfStripesForWidth {
    return floorf(self.bounds.size.width/[self stripeWidth]);
}

@end
