//
//  SQThreadCell.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQThreadCell.h"
#import "NPContact.h"
#import <QuartzCore/QuartzCore.h>
#import "SQAPI.h"
#import "SQMainViewController.h"
#import "SQTheme.h"
#import "SQFriendsOnSquawk.h"
#import "SQLongPressGestureRecognizer.h"
#import "SQDateFormatter.h"
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import "SQThreadListViewController.h"
#import "UIViewController+SoftModal.h"

const CGFloat SQThreadCellSwipeButtonWidth = 120;
const CGFloat SQCheckmarkPullThreshold = 60;

NSString *const SQCheckmarkVisibleNextToThreadIdentifier = @"SQCheckmarkVisibleNextToThreadIdentifier";

@interface SQThreadCell () <UIScrollViewDelegate> {
    NSArray* _swipeButtonDefs;
    NSMutableArray* _swipeButtons;
    
    UIView* _checkmarkIcon;
}

@property(nonatomic)BOOL checkmarkEnabled;
@property(nonatomic)BOOL checkmarkAnimationInProgress;
@property(nonatomic)CGFloat checkmarkPullProgress;

@end

@implementation SQThreadCell

-(BOOL)isCellCurrentlyVisible {
    UITableView* tableView = nil;
    UIView* superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UITableView class]]) {
            tableView = (id)superview;
            break;
        } else {
            superview = superview.superview;
        }
    }
    return tableView && [tableView indexPathForCell:self];
}
-(void)setup {
    if (_setup) return;
    _setup = YES;
    
    _background.layer.borderColor = [UIColor whiteColor].CGColor;
    
    _reloader = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(reload) userInfo:nil repeats:YES];
    
    self.gestureRec = [[SQLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
    [(SQLongPressGestureRecognizer*)self.gestureRec setTimeUntilCancellingScrolling:0.7];
    self.gestureRec.minimumPressDuration = 0.3;
    self.gestureRec.delegate = self;
    [self addGestureRecognizer:self.gestureRec];
    
    static UIImage *recordImage = nil;
    static UIImage *recordImageHighlighted = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recordImage = [[UIImage imageNamed:@"bird"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        recordImageHighlighted = [[UIImage imageNamed:@"bird-circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    //self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    //self.layer.shouldRasterize = YES;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_background attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_background attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.background addGestureRecognizer:tapRec];
    
    RAC(self, checkmarkPullProgress) = [RACObserve(self.scrollView, contentOffset) map:^id(id value) {
        CGFloat x = -[value CGPointValue].x;
        return @(MAX(0, MIN(1, x/SQCheckmarkPullThreshold)));
    }];
    RAC(self, checkmarkEnabled) = [[RACSignal combineLatest:@[RACObserve(self, thread), [[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:SQCheckmarkVisibleNextToThreadIdentifier observer:self]]] reduceEach:^id(SQThread* thread, NSString* identifierForCheckmark){
        return @([identifierForCheckmark isEqualToString:[thread identifier]]);
    }];
    
    UIImage* checkmarkImage = [UIImage imageNamed:@"circled-check-light"];
    _checkmarkIcon = [[UIImageView alloc] initWithImage:checkmarkImage];
    _checkmarkIcon.bounds = CGRectMake(0, 0, 30, 30);
    [self.scrollView addSubview:_checkmarkIcon];
    
    RAC(_checkmarkIcon, hidden) = [RACObserve(self, checkmarkEnabled) not];
    
    [RACObserve(self, checkmarkPullProgress) subscribeNext:^(id x) {
        if (!self.checkmarkAnimationInProgress && [x floatValue]==1 && self.checkmarkEnabled) {
            [self startCheckmarkAnimation];
            [self postCheckmark];
        }
    }];
    RAC(_checkmarkIcon, center) = [RACObserve(self, checkmarkPullProgress) map:^id(id value) {
        CGFloat progress = [value floatValue];
        return [NSValue valueWithCGPoint:CGPointMake(-SQCheckmarkPullThreshold/2, self.bounds.size.height/2-progress*20)];
    }];
    
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
}
-(void)tapped:(UITapGestureRecognizer*)gestureRec {
    if (gestureRec.state == UIGestureRecognizerStateRecognized) {
        NSIndexPath* indexPath = [self.controller.tableView indexPathForCell:self];
        [self.controller.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.controller tableView:self.controller.tableView didSelectRowAtIndexPath:indexPath];
    }
}
-(void)setThread:(SQThread *)thread {
    _thread = thread;
    
    [self setup];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SQThreadUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:SQThreadUpdatedNotification object:thread];
    [self reload];
}
-(void)reload {
    _label.attributedText = [self attributedTitle];
    int unread = (int)self.thread.unread.count;
    _unreadCount.text = unread? [NSString stringWithFormat:@"%i", unread] : @"";
    
    UIColor* tint = unread? [SQTheme rowColorForPlayback] : [SQTheme rowColorForRecording];
    CGFloat hue, sat, brightness;
    [tint getHue:&hue saturation:&sat brightness:&brightness alpha:nil];
    sat = sat*0.7 + self.saturation*0.3;
    brightness = brightness*0.7 + self.brightness*0.3;
    tint = [UIColor colorWithHue:hue saturation:sat brightness:brightness alpha:1];
    _background.backgroundColor = self.tintColor = tint;
    
    if (self.thread.squawks.count) {
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:[self.thread.squawks.firstObject[@"date"] doubleValue]];
        _date.text = [SQDateFormatter formatDate:date];
    } else {
        _date.text = nil;
    }
    
    [self resetSwipeButtons];
}
-(NSAttributedString*)attributedTitle {
    NSArray* unread = self.thread.unread;
    NSMutableSet* phoneNumbersWithUnreadSquawks = [NSMutableSet new];
    for (NSDictionary* squawk in unread) {
        [phoneNumbersWithUnreadSquawks addObject:squawk[@"sender"]];
    }
    
    NSSet* registeredPhoneNumbers = [[[SQFriendsOnSquawk shared] setOfPhoneNumbersOfFriendsOnSquawk] first];
    NSMutableSet* receivedSquawksFromPhones = [NSMutableSet new];
    for (NSDictionary* squawk in self.thread.squawks) {
        [receivedSquawksFromPhones addObject:squawk[@"sender"]];
    }
    
    NSMutableAttributedString* title = [NSMutableAttributedString new];
    
    NSArray* phoneNumbers = self.thread.numbersToDisplay;
    
    BOOL showLongNames = phoneNumbers.count==1;
    
    for (int i=0; i<phoneNumbers.count; i++) {
        NSString* phoneNumber = phoneNumbers[i];
        NSString* name = showLongNames? [SQThread nameForNumber:phoneNumber] : [SQThread shortNameForNumber:phoneNumber];
        BOOL registered = [receivedSquawksFromPhones containsObject:phoneNumber] || [registeredPhoneNumbers containsObject:phoneNumber] || [SQThread specialNames][phoneNumber];
        BOOL hasUnread = [phoneNumbersWithUnreadSquawks containsObject:phoneNumber];
        
        NSDictionary* attrs = @{
                                NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:registered? 1 : 0.7],
                                NSFontAttributeName: hasUnread? [UIFont fontWithName:@"AvenirNext-Medium" size:16] : [UIFont fontWithName:@"AvenirNext-Regular" size:16]
                                };
        
        if (i+1 < phoneNumbers.count) {
            if (i+1 == phoneNumbers.count-1) name = [name stringByAppendingString:@" and "];
            else name = [name stringByAppendingString:@", "];
        }
        [title appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:attrs]];
    }
    
    return title;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SQThreadUpdatedNotification object:nil];
    [_reloader invalidate];
}

-(IBAction)pressed:(UILongPressGestureRecognizer*)sender {
    if (sender.state==UIGestureRecognizerStateBegan) {
        self.controller.touchPoint = [sender locationInView:self.controller.view];
        self.controller.pressedThread = self.thread;
    } else if (sender.state==UIGestureRecognizerStateCancelled||sender.state==UIGestureRecognizerStateEnded||sender.state==UIGestureRecognizerStateFailed) {
        self.controller.pressedThread = nil;
    };
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
-(void)scrolled {
    [self.gestureRec setEnabled:NO];
    [self.gestureRec setEnabled:YES];
    [self closeSwipeMenu];
}
-(void)setSqSelected:(BOOL)sqSelected {
    _sqSelected = sqSelected;
    
    CGFloat borderWidth = sqSelected? 3 : 0;
    if (borderWidth != _background.layer.borderWidth) {
        CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
        //anim.removedOnCompletion = YES;
        anim.fillMode = kCAFillModeForwards;
        anim.fromValue = @(_background.layer.borderWidth);
        anim.toValue = @(borderWidth);
        anim.duration = 0.2;
        [_background.layer addAnimation:anim forKey:@"Border"];
        _background.layer.borderWidth = borderWidth;
    }
}
-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
}
-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    
}
-(void)setInteracting:(BOOL)interacting {
    _interacting = interacting;
    _label.alpha = _date.alpha = _unreadCount.alpha = interacting? 0.1 : 1;
}
-(void)prepareForReuse {
    [super prepareForReuse];
    self.interacting = NO;
}
#pragma mark Layout
-(void)layoutSubviews {
    [super layoutSubviews];
    _scrollView.contentSize = CGSizeMake(self.bounds.size.width + SQThreadCellSwipeButtonWidth*[self swipeButtonDefs].count, self.bounds.size.height);
    if (_swipeButtons) {
        CGFloat x = self.bounds.size.width;
        for (UIButton* button in _swipeButtons) {
            button.frame = CGRectMake(x, 0, SQThreadCellSwipeButtonWidth, self.bounds.size.height);
            x += SQThreadCellSwipeButtonWidth;
        }
    }
}
#pragma mark Swipe menu
-(void)resetSwipeButtons {
    _swipeButtonDefs = nil;
    /*if (self.scrollView.contentOffset.x > 0) {
        NSArray* buttons = _swipeButtons;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            for (UIButton* b in buttons) {
                b.alpha = 0;
            }
        } completion:^(BOOL finished) {
            for (UIButton* b in buttons) {
                [b removeFromSuperview];
            }
        }];
    } else {
        for (UIButton* button in _swipeButtons) [button removeFromSuperview];
    }*/
    for (UIButton* button in _swipeButtons) [button removeFromSuperview];
    
    _swipeButtons = nil;
    if (self.scrollView.contentOffset.x > 0) {
        [self generateSwipeButtons];
    }
    [self setNeedsLayout];
}
-(NSArray*)swipeButtonDefs { // array of dictionaries with "title" and "action" keys
    if (!_swipeButtonDefs) {
        NSMutableArray* buttonDefs = [NSMutableArray new];
        int otherThreadMembers = self.thread.phoneNumbers.count-1;
        if (self.thread.unread.count > 0) {
            [buttonDefs addObject:@{
                                    @"title": NSLocalizedString(@"Delete squawks", @""),
                                    @"action": @"deleteUnread"
                                    }];
        }
        if (otherThreadMembers > 1) { // group squawk
            [buttonDefs addObject:@{
                                    @"title": NSLocalizedString(@"People", @""),
                                    @"action": @"showPeopleDetail"
                                    }];
        }
        if (otherThreadMembers == 1) {
            NSString* phone = self.thread.phoneNumbers.anyObject;
            if (phone && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:17185551234"]]) {
                [buttonDefs addObject:@{
                                        @"title": NSLocalizedString(@"Call", @""),
                                        @"action": @"call"
                                        }];
            }
            if (self.thread.contacts.count==0) {
                [buttonDefs addObject:@{
                                        @"title": NSLocalizedString(@"Add contact", @""),
                                        @"action": @"addContact"
                                        }];
            }
        }
        if ([MFMessageComposeViewController canSendText]) {
            [buttonDefs addObject:@{
                                    @"title": NSLocalizedString(@"Message", @""),
                                    @"action": @"message"
                                    }];
        }
        _swipeButtonDefs = buttonDefs;
    }
    return _swipeButtonDefs;
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (!_swipeButtons) {
        [self generateSwipeButtons];
    }
}
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat endPoint = 0;
    for (int i=0; i<_swipeButtons.count; i++) {
        CGFloat x = SQThreadCellSwipeButtonWidth*(i+1);
        if (fabsf(x-targetContentOffset->x) < fabsf(endPoint-targetContentOffset->x)) {
            endPoint = x;
        }
    }
    targetContentOffset->x = endPoint;
}
-(void)generateSwipeButtons {
    
    _swipeButtons = [NSMutableArray new];
    CGFloat alpha = 1;
    for (NSDictionary* def in [self swipeButtonDefs].reverseObjectEnumerator) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[def[@"title"] lowercaseString] forState:UIControlStateNormal];
        [button addTarget:self action:NSSelectorFromString(def[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:button];
        alpha -= 0.2;
        button.backgroundColor = [self.background.backgroundColor colorWithAlphaComponent:alpha];
        button.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14];
        [_swipeButtons addObject:button];
    }
    
    [self setNeedsLayout];
}
-(void)closeSwipeMenu {
    if (_scrollView.contentOffset.x > 0) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _scrollView.contentOffset = CGPointZero;
        } completion:^(BOOL finished) {
            
        }];
    }
}
#pragma mark Swipe menu actions
-(void)showPeopleDetail {
    SQThreadListViewController* detail = [self.controller.storyboard instantiateViewControllerWithIdentifier:@"ThreadList"];
    NSMutableArray* phones = self.thread.phoneNumbers.allObjects.mutableCopy;
    [phones removeObject:[SQAPI currentPhone]];
    detail.threadMembers = phones;
    [detail presentSoftModalInViewController:self.controller];
}
-(void)deleteUnread {
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentOffset = CGPointZero;
    } completion:^(BOOL finished) {
        NSTimeInterval totalTime = self.thread.unread.count==1? 0.1 : 1.0;
        [SQThread deleteSquawks:self.thread.unread intervalBetweenEach:totalTime/self.thread.unread.count];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((totalTime+0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.scrollView setContentOffset:CGPointZero animated:YES];
        });
    }];
}
-(void)call {
    NSString* phone = self.thread.singlePhone;
    if (phone) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phone]]];
    }
}
-(void)message {
    NSMutableArray* phones = self.thread.phoneNumbers.allObjects.mutableCopy;
    [phones removeObject:[SQAPI currentPhone]];
    if (phones.count) {
        [self.controller sendMessageToPhones:phones];
    }
}
-(void)addContact {
    NSString* phone = self.thread.singlePhone;
    if (phone) {
        [self.controller promptToAddContactWithPhone:phone];
    }
}
#pragma mark Checkmark
-(void)startCheckmarkAnimation {
    self.checkmarkAnimationInProgress = YES;
    
    UIView* snapshot = [_checkmarkIcon snapshotViewAfterScreenUpdates:NO];
    UIView* rootView = AppDelegate.window.rootViewController.view;
    [rootView addSubview:snapshot];
    NSTimeInterval duration = 0.6;
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGPoint fromPt = [rootView convertPoint:_checkmarkIcon.center fromView:_checkmarkIcon.superview];
    CGPoint toPt = [rootView convertPoint:CGPointMake(self.window.rootViewController.view.frame.size.width+_checkmarkIcon.frame.size.width, -_checkmarkIcon.frame.size.height) fromView:self.window.rootViewController.view];
    CGPoint controlPt = CGPointMake(fromPt.x, toPt.y-30);
    [path moveToPoint:fromPt];
    [path addCurveToPoint:toPt controlPoint1:controlPt controlPoint2:controlPt];
    CAKeyframeAnimation* anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.path = path.CGPath;
    anim.fillMode = kCAFillModeForwards;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [snapshot.layer addAnimation:anim forKey:@"move"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [snapshot.layer removeAnimationForKey:@"move"];
        [snapshot removeFromSuperview];
        self.checkmarkAnimationInProgress = NO;
    });
}
-(void)postCheckmark {
    NSString* threadIdentifier = self.thread.identifier;
    NSMutableArray* sendCheckmarksToPhones = self.thread.phoneNumbers.allObjects.mutableCopy;
    [sendCheckmarksToPhones removeObject:[SQAPI currentPhone]];
    [SQAPI post:@"/send_checkmark" args:@{@"recipients": sendCheckmarksToPhones, @"thread_identifier": threadIdentifier} data:nil callback:^(NSDictionary *result, NSError *error) {
        if (![result[@"success"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppDelegate toast:NSLocalizedString(@"Couldn't send checkmark.", @"")];
            });
        }
    }];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SQCheckmarkVisibleNextToThreadIdentifier];
    [AppDelegate trackEventWithCategory:@"action" action:@"sent_checkmark" label:nil value:nil];
}

@end
