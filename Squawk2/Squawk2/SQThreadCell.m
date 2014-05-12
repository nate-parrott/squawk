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
    
    _reloader = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(reload) userInfo:nil repeats:YES];
    
    self.gestureRec = [[SQLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
    [(SQLongPressGestureRecognizer*)self.gestureRec setDurationBeforeTouchLock:0.7];
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
    [_button setImage:recordImage forState:UIControlStateNormal];
    [_button setImage:recordImageHighlighted forState:UIControlStateHighlighted];
    _button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
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
    _button.transform = CGAffineTransformMakeScale(unread? -1 : 1, 1);
    _unreadCount.text = unread? [NSString stringWithFormat:@"%i", unread] : @"";
    self.tintColor = unread? [SQTheme blue] : [SQTheme red];
    _unreadCount.textColor = self.tintColor;
    
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
                                NSForegroundColorAttributeName: registered? [UIColor blackColor] : [UIColor grayColor],
                                NSFontAttributeName: hasUnread? [UIFont fontWithName:@"AvenirNext-Medium" size:18] : [UIFont fontWithName:@"AvenirNext-Regular" size:18]
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

@end
