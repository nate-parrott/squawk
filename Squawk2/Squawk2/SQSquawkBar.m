//
//  SQSquawkBar.m
//  Squawk2
//
//  Created by Nate Parrott on 4/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQSquawkBar.h"
#import "SQTheme.h"
#import "SQSquawkBarSegment.h"
#import "SQThreadCell.h"
#import "SQCheckmarkSegment.h"

const CGFloat SQSquawkBarSegmentOverlap = 25;
const CGFloat SQSquawkBarCheckmarkPullThreshold = 90;

@interface SQSquawkBar () <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    UIScrollView* _scrollView;
    UIView *_redBackground, *_blueBackground;
    SQSquawkBarSegment *_recordLabel, *_playbackLabel, *_inviteLabel;
    SQCheckmarkSegment* _checkmarkLabel;
    UIButton* _button;
    
    CGFloat _checkmarkPullProgress;
    
    UITapGestureRecognizer* _tapRec;
}

@end


@implementation SQSquawkBar

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}
-(void)setup {
    _scrollView = [UIScrollView new];
    _scrollView.delegate = self;
    [self addSubview:_scrollView];
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _scrollView.alwaysBounceHorizontal = YES;
    
    self.clipsToBounds = YES;
    
    _recordLabel = [SQSquawkBarSegment new];
    _playbackLabel = [SQSquawkBarSegment new];
    _checkmarkLabel = [SQCheckmarkSegment new];
    _inviteLabel = [SQSquawkBarSegment new];
    for (SQSquawkBarSegment* segment in @[_recordLabel, _playbackLabel, _checkmarkLabel, _inviteLabel]) {
        [_scrollView addSubview:segment];
        segment.label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:12];
        segment.label.textColor = [UIColor whiteColor];
        segment.label.numberOfLines = 0;
        segment.label.lineBreakMode = NSLineBreakByWordWrapping;
        segment.label.textAlignment = NSTextAlignmentCenter;
    }
    _recordLabel.backgroundView.backgroundColor = [SQTheme red];
    _playbackLabel.backgroundView.backgroundColor = [SQTheme blue];
    _checkmarkLabel.backgroundView.backgroundColor = [SQTheme lightGray];;
    _inviteLabel.label.text = NSLocalizedString(@"Invite", @"").lowercaseString;
    _inviteLabel.label.textAlignment = NSTextAlignmentRight;
    _inviteLabel.backgroundView.backgroundColor = [SQTheme lightBlue];//[UIColor colorWithWhite:0.5 alpha:1];
    _inviteLabel.labelInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    
    RAC(_checkmarkLabel, hidden) = [RACObserve(self, showCheckmarkControl) not];
    RAC(_inviteLabel, hidden) = [RACObserve(self, showInviteControl) not];
    RAC(_playbackLabel, hidden) = [RACObserve(self, allowsPlayback) not];
    
    RAC(_playbackLabel.label, attributedText) = RACObserve(self, playbackMessage);
    RAC(_recordLabel.label, attributedText) = RACObserve(self, recordMessage);
    
    [RACObserve(self, allowsPlayback) subscribeNext:^(id x) {
        [self setNeedsLayout];
    }];
    
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_button];
    [_button addTarget:self action:@selector(tapDown) forControlEvents:UIControlEventTouchDown];
    [_button addTarget:self action:@selector(tapUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    
    _redBackground = [UIView new];
    _redBackground.backgroundColor = [SQTheme red];
    _blueBackground = [UIView new];
    _blueBackground.backgroundColor = [SQTheme blue];
    [_scrollView insertSubview:_redBackground atIndex:0];
    [_scrollView insertSubview:_blueBackground aboveSubview:_redBackground];
    RAC(_blueBackground, hidden) = [RACObserve(self, allowsPlayback) not];
    
    _tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:_tapRec];
}
-(void)tapDown {
    [self.delegate playbackOrRecordHeldDown:self];
}
-(void)tapUp {
    [self.delegate playbackOrRecordPickedUp:self];
}
-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView* pullable in [self pullableViews]) {
        if ([pullable pointInside:[pullable convertPoint:point fromView:self] withEvent:event]) {
            return _scrollView;
        }
    }
    return _button;
}
-(NSArray*)pullableViews {
    NSMutableArray* pullableViews = [@[_inviteLabel, _checkmarkLabel] mutableCopy];
    if (self.showingPlayback) {
        [pullableViews addObject:_recordLabel];
    } else {
        [pullableViews addObject:_playbackLabel];
    }
    return pullableViews;
}
-(void)showPlayback:(BOOL)showing {
    [self layoutIfNeeded];
    [_scrollView setContentOffset:CGPointMake(showing? _scrollView.bounds.size.width-SQSquawkBarSegmentOverlap*2 : 0, 0)];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    _scrollView.frame = self.bounds;
    _recordLabel.frame = CGRectMake(SQSquawkBarSegmentOverlap, 0, self.bounds.size.width-SQSquawkBarSegmentOverlap*2, self.bounds.size.height);
    _playbackLabel.frame = CGRectMake(self.bounds.size.width-SQSquawkBarSegmentOverlap, 0, self.bounds.size.width-SQSquawkBarSegmentOverlap*2, self.bounds.size.height);
    CGFloat scrollWidth = self.allowsPlayback? self.bounds.size.width*2 - SQSquawkBarSegmentOverlap*2 : self.bounds.size.width;
    _scrollView.contentSize = CGSizeMake(scrollWidth, self.bounds.size.height);
    _checkmarkLabel.frame = CGRectMake(_scrollView.contentSize.width-SQSquawkBarSegmentOverlap, 0, 200, self.bounds.size.height);
    _inviteLabel.frame = CGRectMake(50-200, 0, 200, self.bounds.size.height);
    _button.frame = self.bounds;
    
    _redBackground.frame = CGRectMake(-200, 0, self.bounds.size.width+200, self.bounds.size.height);
    _blueBackground.frame = CGRectMake(self.bounds.size.width, 0, self.bounds.size.width+200, self.bounds.size.height);
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL showingPlayback = scrollView.contentOffset.x > self.bounds.size.width/2;
    if (showingPlayback != _showingPlayback) {
        self.showingPlayback = showingPlayback;
    }
    
    CGFloat maxContentOffset = scrollView.contentSize.width-scrollView.frame.size.width;
    CGFloat pullProgress = MAX(0, MIN(1, (scrollView.contentOffset.x - maxContentOffset)/SQSquawkBarCheckmarkPullThreshold));
    if (!self.showCheckmarkControl) pullProgress = 0;
    _checkmarkLabel.pullProgress = pullProgress;
    if (pullProgress == 1 && !_checkmarkLabel.waitingForReset) {
        [self sendCheckmark];
    }
}
-(void)sendCheckmark {
    [_checkmarkLabel animateSendingCheckmark:^{
        // we'll actually SEND the checkmark when the user picks up their finger
    }];
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_checkmarkLabel.waitingForReset) {
        [UIView animateWithDuration:0.6 animations:^{
            _checkmarkLabel.transform = CGAffineTransformMakeTranslation(SQSquawkBarSegmentOverlap+10, 0);
        } completion:^(BOOL finished) {
            _checkmarkLabel.transform = CGAffineTransformIdentity;
            self.showCheckmarkControl = NO;
            // send it:
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SQCheckmarkVisibleNextToThreadIdentifier];
            [self.delegate sendCheckmark:self];
        }];
    }
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat offsets[] = {0, _scrollView.contentSize.width-_scrollView.frame.size.width};
    CGFloat landing = offsets[0];
    if (fabsf(offsets[1]-targetContentOffset->x) < fabsf(landing-targetContentOffset->x)) {
        landing = offsets[1];
    }
    targetContentOffset->x = landing;
}

-(UIView*)pullableViewUnderPoint:(CGPoint)pointInSelf {
    for (UIView* view in [self pullableViews]) {
        if (!view.hidden &&
            [view pointInside:[view convertPoint:pointInSelf fromView:self] withEvent:nil]) {
            return view;
        }
    }
    return nil;
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView* touched = [self pullableViewUnderPoint:[touch locationInView:self]];
    return !!touched;
}
-(void)tapped:(UITapGestureRecognizer*)gestureRec {
    if (gestureRec.state == UIGestureRecognizerStateRecognized) {
        UIView* touched = [self pullableViewUnderPoint:[gestureRec locationInView:self]];
        if (touched==_inviteLabel) {
            [self.delegate inviteFriend:self];
        } else if (touched==_checkmarkLabel) {
            [self bounceInDirection:1];
        } else if (touched==_recordLabel) {
            [self bounceInDirection:-1];
        } else if (touched==_playbackLabel) {
            [self bounceInDirection:1];
        }
    }
}
-(void)bounceInDirection:(CGFloat)direction {
    CGPoint existingOffset = _scrollView.contentOffset;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _scrollView.contentOffset = CGPointMake(existingOffset.x + 10*direction, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
            _scrollView.contentOffset = existingOffset;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

@end
