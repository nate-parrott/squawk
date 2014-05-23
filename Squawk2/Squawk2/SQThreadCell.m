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

NSString *const SQCheckmarkVisibleNextToThreadIdentifier = @"SQCheckmarkVisibleNextToThreadIdentifier";

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
    static UIImage *checkmarkImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recordImage = [[UIImage imageNamed:@"bird"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        recordImageHighlighted = [[UIImage imageNamed:@"bird-circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        checkmarkImage = [[UIImage imageNamed:@"check-button"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    //self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    //self.layer.shouldRasterize = YES;
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
#pragma mark Swipe menu
-(NSArray*)swipeButtons { // array of dictionaries with "title" and "action" keys
    
}

@end
