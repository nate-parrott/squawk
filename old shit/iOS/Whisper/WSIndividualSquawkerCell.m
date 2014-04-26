//
//  WSIndividualSquakerCell.m
//  Squawk
//
//  Created by Nate Parrott on 2/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSIndividualSquawkerCell.h"
#import "WSMessageSender.h"
#import "WSAppDelegate.h"
#import "WSMainViewController.h"
#import "WSThreadSender.h"

@implementation WSIndividualSquawkerCell

-(void)prepareForReuse {
    self.model = nil;
    [super prepareForReuse];
}
-(void)setModel:(WSMessageSender*)model {
    _model = model;
    
    if (!_setupYet) {
        [self setup];
    }
    
    NSString* name = _model.displayName? : @"";
    int unreadCount = self.playlist.count;
    
    self.label.attributedText = [_model attributedLabel];
     
    self.state = WSCellStateSilent;
    
    NSString* accessibilityName = name.length? name : _model.nickname;
    if (unreadCount==0) {
        if ([_model isRegistered]) {
            self.accessibilityLabel = accessibilityName;
        } else {
            self.accessibilityLabel = [NSString stringWithFormat:@"%@ (doesn't have Squawk)", accessibilityName];
        }
    } else if (unreadCount==1) {
        self.accessibilityLabel = [NSString stringWithFormat:@"%@: one new Squawk", accessibilityName];
    } else {
        self.accessibilityLabel = [NSString stringWithFormat:@"%@: %i new Squawks", accessibilityName, unreadCount];
    }
    self.recordingButton.accessibilityLabel = [NSString stringWithFormat:@"Send a Squawk to %@", accessibilityName];
    
    if (self.confirmationUIVisible) {
        self.confirmationUIVisible = NO;
    }
}
-(void)setup {
    _setupYet = YES;
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil] subscribeNext:^(id x) {
        [self cancel];
    }];
    // register for autoplay notifications:
    RACSignal* becameActive = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] startWith:nil];
    [[RACSignal combineLatest:@[RACObserve(AppDelegate, autoplayMessageID), RACObserve(self, model), becameActive, RACObserve(self, visible)]] subscribeNext:^(RACTuple* items) {
        BOOL visible = [items.fourth boolValue];
        if (visible) {
            NSString* autoplayID = items.first;
            if (!autoplayID) return;
            
            BOOL autoplayIDIsFresh = [NSDate timeIntervalSinceReferenceDate] - AppDelegate.timeOfAutoplayInvocation.timeIntervalSinceReferenceDate < 6;
            if ([UIApplication sharedApplication].applicationState==UIApplicationStateActive) {
                BOOL autoplay = NO;
                for (PFObject* msg in self.playlist) {
                    if ([[msg valueForKey:@"id2"] isEqualToString:autoplayID]) {
                        autoplay = YES;
                    }
                }
                if (autoplay && autoplayIDIsFresh) {
                    AppDelegate.autoplayMessageID = nil;
                    [self startPlayback];
                }
            }
        }
    }];
}
-(NSArray*)playlist {
    return self.model.unread;
}
-(void)updateDisplay {
    [self setModel:self.model]; // trigger a view reload
}
-(IBAction)confirm:(id)sender {
    NSString* fromPhoneNumber = [[PFUser currentUser] valueForKey:@"username"];
    NSMutableArray* toUsers = [NSMutableArray arrayWithObject:[_model.messages.firstObject valueForKey:@"sender"]];
    if ([_model.messages.firstObject valueForKey:@"threadMembers"]) {
        [toUsers addObjectsFromArray:[_model.messages.firstObject valueForKey:@"threadMembers"]];
    }
    NSArray* toPhoneNumbers = [[toUsers.rac_sequence filter:^BOOL(id value) {
        return ![[value objectId] isEqualToString:[PFUser currentUser].objectId];
    }] map:^id(id value) {
        return [value valueForKey:@"username"];
    }].array;
    
    NSString* fromNickname = [[PFUser currentUser] valueForKey:@"nickname"];
    [PFCloud callFunctionInBackground:@"confirm" withParameters:@{@"from": fromPhoneNumber, @"fromNickname": fromNickname, @"toPhones": toPhoneNumbers} block:^(id object, NSError *error) {
        
    }];
    [super confirm:sender];
}
-(NSArray*)phoneNumbers {
    return [_model phoneNumbersToSendTo];
}

@end
