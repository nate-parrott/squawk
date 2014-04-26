//
//  WSMessageSender.h
//  Squawk
//
//  Created by Nate Parrott on 1/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPContact.h"

@interface WSMessageSender : NSObject {
    NSArray* _phoneNumbers;
    
    NSString* _equivalenceToken;
    
    NSTimeInterval _dateForSortingCache;
    
    enum {
        unknown=0,
        registered=1,
        unregistered=2
    } _isRegisteredCache;
}

@property(strong,readonly)NSMutableArray* messages;

-(NSArray*)unread;

-(NSArray*)phoneNumbers;
-(NSString*)preferredPhoneNumber;
-(NSArray*)phoneNumbersToSendTo;

-(NSString*)displayName;
-(NSString*)nickname;
-(NSAttributedString*)attributedLabel;

-(BOOL)isGroupThread;

-(void)generateSearchableName;
@property(strong)NSString* searchableName;

@property(strong)NPContact* contact; // optional

-(BOOL)isRegistered;

-(NSTimeInterval)dateForSorting;

+(id)participantIdentifierForMessage:(PFObject*)msg;
+(BOOL)isMessageThreaded:(PFObject*)msg;

-(BOOL)isEquivalentTo:(WSMessageSender*)other;

@end
