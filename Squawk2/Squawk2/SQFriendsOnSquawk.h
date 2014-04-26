//
//  SQFriendsOnSquawk.h
//  Squawk2
//
//  Created by Nate Parrott on 3/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#define SQ_FRIEND_UPDATE_INTERVAL 24 * 60 * 60

NSString* SQPhoneNumbersOfFriendsOnSquawk;

@interface SQFriendsOnSquawk : NSObject <MFMessageComposeViewControllerDelegate, UIAlertViewDelegate> {
    MFMessageComposeViewController* _messageComposer;
    NSString* _invitationPrompt;
}

+(SQFriendsOnSquawk*)shared;

-(RACSignal*)setOfPhoneNumbersOfFriendsOnSquawk;
-(void)gotPhonesOfFriendsOnSquawk:(NSArray*)phones;

-(void)sendInvitesToUsersIfNecessary:(NSArray*)phones prompt:(NSString*)prompt;
-(void)sendInvitationMessage:(NSString*)prompt toPhones:(NSArray*)phones;

+(NSString*)genericInvitationPrompt;
+(NSString*)receivedMessageInvitationPrompt;

@end
