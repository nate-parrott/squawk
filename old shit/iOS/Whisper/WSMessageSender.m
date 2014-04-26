//
//  WSMessageSender.m
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSMessageSender.h"
#import "ConvenienceCategories.h"
#import "WSFriendsOnSquawk.h"
#import "NSString+NormalizeForSearch.h"
#import "WSSquawkerCell.h"
#import "WSContactBoost.h"
#import "WSThreadSender.h"


@implementation WSMessageSender

-(id)init {
    self = [super init];
    _messages = [NSMutableArray new];
    return self;
}

-(void)generateSearchableName {
    self.searchableName = [self.displayName normalizedForSearch];
}

-(NSArray*)unread {
    return [[_messages map:^id(id obj) {
        return [WSSquawkerCell hasSquawkBeenListenedTo:obj]==NO? obj : nil;
    }] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
}

-(NSArray*)phoneNumbers {
    if (!_phoneNumbers) {
        NSMutableSet* nums = [NSMutableSet new];
        for (PFObject* message in self.messages) {
            [nums addObject:[[message valueForKey:@"sender"] valueForKey:@"username"]];
        }
        for (NSString* num in self.contact.phoneNumbers) {
            [nums addObject:num];
        }
        _phoneNumbers = nums.allObjects;
    }
    return _phoneNumbers;
}
-(NSString*)preferredPhoneNumber {
    for (PFObject* message in self.messages) {
        return [[message valueForKey:@"sender"] valueForKey:@"username"];
    }
    NSString* contactNum = [self.contact mobileNumber];
    if (contactNum) {
        return contactNum;
    }
    return nil;
}
#define TEAM_SQUAWK_NUMBER @"15555551234"
-(BOOL)computeIsRegistered {
    if (self.messages.count > 0) {
        return YES;
    }
    NSSet* registered = [[WSFriendsOnSquawk manager] phoneNumbersOfFriendsOnSquawk];
    for (NSString* num in self.phoneNumbers) {
        if ([registered containsObject:num]) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)isRegistered {
    if (_isRegisteredCache==unknown) {
        _isRegisteredCache = [self computeIsRegistered]? registered : unregistered;
    }
    return _isRegisteredCache==registered;
}

-(NSDate*)latestMessage {
    NSDate* latest = nil;
    for (PFObject* msg in self.messages) {
        if (latest==nil || [latest compare:[msg valueForKey:@"createdAt"]] == NSOrderedAscending) {
            latest = [msg valueForKey:@"createdAt"];
        }
    }
    return latest;
}

+(BOOL)isMessageThreaded:(PFObject*)msg {
    return [[msg valueForKey:@"threadMembers"] count] > 0;
}
+(id)participantIdentifierForMessage:(PFObject*)msg {
    if ([self isMessageThreaded:msg]) {
        NSMutableArray* usernames = [NSMutableArray new];
        for (PFUser* member in [msg valueForKey:@"threadMembers"]) {
            [usernames addObject:[member valueForKey:@"username"]];
        }
        return [[usernames sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","];
    } else {
        return [[msg valueForKey:@"sender"] valueForKey:@"username"];
    }
}
-(NSArray*)phoneNumbersToSendTo {
    return self.preferredPhoneNumber? @[self.preferredPhoneNumber] : @[];
}
#pragma mark Labeling
-(NSString*)displayName {
    if (self.contact) {
        NSString* label = self.contact.displayLabel;
        if (label) return label;
    }
    PFUser* sender = [self.messages.firstObject valueForKey:@"sender"];
    NSString* num = [sender valueForKey:@"username"];
    if ([num isEqualToString:TEAM_SQUAWK_NUMBER]) {
        return @"Team Squawk";
    }
    return num;
}
-(NSString*)nickname {
    PFUser* sender = [self.messages.firstObject valueForKey:@"sender"];
    NSString* nickname = [sender valueForKey:@"nickname"];
    if ([[sender valueForKey:@"username"] isEqualToString:TEAM_SQUAWK_NUMBER]) {
        if (self.unread.count) {
            return @"Tap to listen";
        } else {
            return @"Hold the bird button to Squawk back";
        }
    }
    return nickname;
}
-(NSAttributedString*)attributedLabel {
    NSString* mainLine = self.displayName;
    if (self.unread.count) mainLine = [NSString stringWithFormat:@"%@ (%i)", mainLine, self.unread.count];
    UIFont* mainLineFont = self.unread.count? [UIFont fontWithName:@"Avenir-Heavy" size:18] : [UIFont fontWithName:@"Avenir" size:18];
    UIColor* mainLineColor = [self isRegistered]? [UIColor blackColor] : [UIColor grayColor];
    NSAttributedString* mainLineAttributed = [[NSAttributedString alloc] initWithString:mainLine attributes:@{NSFontAttributeName: mainLineFont, NSForegroundColorAttributeName: mainLineColor}];
    
    NSString* detailLine = self.nickname? : @"";
    UIFont* detailFont = [UIFont fontWithName:@"Avenir" size:12];
    NSAttributedString* detailLineAttributed = [[NSAttributedString alloc] initWithString:detailLine attributes:@{NSFontAttributeName: detailFont, NSForegroundColorAttributeName: [UIColor grayColor]}];
    
    NSMutableAttributedString* label = [NSMutableAttributedString new];
    [label appendAttributedString:mainLineAttributed];
    if (detailLineAttributed.length) {
        [label appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        [label appendAttributedString:detailLineAttributed];
    }
    
    return label;
}

-(NSTimeInterval)dateForSorting {
    if (_dateForSortingCache==0) {
        _dateForSortingCache = 1;
        NSTimeInterval latestMessage = [self latestMessage].timeIntervalSinceReferenceDate;
        _dateForSortingCache = MAX(latestMessage, _dateForSortingCache);
        if (![self isGroupThread]) {
            for (NSString* num in self.phoneNumbers) {
                NSTimeInterval boost = [(NSDate*)[WSContactBoost boostDatesForPhoneNumbers][num] timeIntervalSinceReferenceDate];
                _dateForSortingCache = MAX(boost, _dateForSortingCache);
            }
        }
    }
    return _dateForSortingCache;
}
-(NSString*)equivanceToken {
    if (!_equivalenceToken) {
        _equivalenceToken = [[self.phoneNumbers sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","];
    }
    return _equivalenceToken;
}
-(BOOL)isEquivalentTo:(WSMessageSender*)other {
    return [[self equivanceToken] isEqualToString:[other equivanceToken]];
}
-(BOOL)isGroupThread {
    return NO;
}

@end
