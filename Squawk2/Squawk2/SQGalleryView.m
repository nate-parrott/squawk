//
//  SQGalleryView.m
//  Squawk2
//
//  Created by Nate Parrott on 5/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQGalleryView.h"

@interface SQGalleryView () <UIScrollViewDelegate>

@property(strong)NSArray* views;
@property(strong)UIScrollView* scrollView;
@property(strong)IBOutlet UIPageControl* pageControl;

@end


@implementation SQGalleryView

-(void)awakeFromNib {
    [super awakeFromNib];
    
    NSMutableArray* views = [NSMutableArray new];
    for (UIView* subview in self.subviews) {
        if (subview != self.pageControl) {
            [views addObject:subview];
        }
    }
    self.views = views;
    
    for (UIView* v in self.views) [v removeFromSuperview];
    self.scrollView = [UIScrollView new];
    [self addSubview:self.scrollView];
    for (UIView* v in self.views) {
        [self.scrollView addSubview:v];
        v.translatesAutoresizingMaskIntoConstraints = YES;
    }
    self.pageControl = [UIPageControl new];
    [self addSubview:self.pageControl];
    self.pageControl.numberOfPages = self.views.count;
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.7];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.delegate = self;
    
    [self addGestureRecognizer:self.scrollView.panGestureRecognizer];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = CGRectInset(self.bounds, 30, 0);
    self.pageControl.center = CGPointMake(self.bounds.size.width/2, 35);
    CGFloat x = 0;
    for (UIView* v in self.views) {
        v.frame = CGRectMake(x, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        x += v.frame.size.width;
    }
    self.scrollView.contentSize = CGSizeMake(x, self.bounds.size.height);
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.pageControl.currentPage = MIN(self.pageControl.numberOfPages-1, MAX(0, roundf(scrollView.contentOffset.x/scrollView.bounds.size.width)));
}
-(void)removeViewAtIndex:(int)index {
    [self.views[index] removeFromSuperview];
    NSMutableArray* views = self.views.mutableCopy;
    [views removeObjectAtIndex:index];
    self.views = views;
    [self setNeedsLayout];
    self.pageControl.numberOfPages = self.views.count;
}

@end

