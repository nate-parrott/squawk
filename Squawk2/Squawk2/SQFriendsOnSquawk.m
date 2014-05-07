//
//  SQFriendsOnSquawk.m
//  Squawk2
//
//  Created by Nate Parrott on 3/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQFriendsOnSquawk.h"
#import "NPAddressBook.h"
#import "WSPersistentDictionary.h"
#import "SQAPI.h"
#import "NSArray+CombineStrings.h"
#import "SQThread.h"

@interface SQFriendsOnSquawk () {
    NSArray* _phonesForInvitationPrompt;
}

@end

@implementation SQFriendsOnSquawk

+(SQFriendsOnSquawk*)shared {
    static SQFriendsOnSquawk* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [SQFriendsOnSquawk new];
    });
    return shared;
}
-(id)init {
    self = [super init];
    
    
    [[RACSignal combineLatest:@[[SQAPI loginStatus], [NPAddressBook contacts]]] subscribeNext:^(RACTuple* t) {
        NSArray* contacts = [t second];
        [self updatedContacts:contacts];
    }];
    
    [[RACSignal combineLatest:@[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil], [SQAPI loginStatus]]] subscribeNext:^(id x) {
        [self reloadFriendsIfNeeded];
    }];
    
    return self;
}

-(void)updatedContacts:(NSArray*)contacts {
    static BOOL updateInProgress = NO;
    if (updateInProgress || ![SQAPI currentPhone]) return;
    NSMutableSet* existingContacts = [[WSPersistentDictionary shared] getObjectForKey:@"SQUploadedPhones" fallback:^id{
        return [NSMutableSet new];
    }];
    
    NSArray* newContacts = [contacts.rac_sequence filter:^BOOL(id value) {
        return [value mobileNumber] && ![existingContacts containsObject:[value mobileNumber]];
    }].array;
    
    NSArray* newPhones = [newContacts.rac_sequence map:^id(id value) {
        return [value mobileNumber];
    }].array;
    NSArray* newNames = [newContacts.rac_sequence map:^id(id value) {
        return [value displayLabel];
    }].array;
    if (newContacts.count) {
        updateInProgress = YES;
        
        NSDictionary* payload = @{@"contact_phones": newPhones, @"contact_names": newNames};
        NSData* data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        [SQAPI post:@"/register_contacts" args:@{} data:data callback:^(NSDictionary *result, NSError *error) {
            updateInProgress = NO;
            
            [existingContacts addObjectsFromArray:newPhones];
            [[WSPersistentDictionary shared] didUpdateValueForKey:@"SQUploadedPhones"];
            
            [self gotPhonesOfFriendsOnSquawk:result[@"phones_on_squawk"]];
            
            [WSPersistentDictionary shared][@"SQLastFriendReload"] = [NSDate distantPast];
            [self reloadFriendsIfNeeded];
        }];
    } else {
        [[WSPersistentDictionary shared] getObjectForKey:@"SQPhoneNumbersOfFriendsOnSquawk" fallback:^id{
            return [NSMutableSet new];
        }];
    }
}

-(void)reloadFriendsIfNeeded {
    static BOOL reloadInProgress = NO;
    if (reloadInProgress || ![SQAPI currentPhone]) return;
    if ([NSDate timeIntervalSinceReferenceDate] - [[WSPersistentDictionary shared][@"SQLastFriendReload"] timeIntervalSinceReferenceDate] > SQ_FRIEND_UPDATE_INTERVAL) {
        reloadInProgress = YES;
        [SQAPI call:@"/check_contacts_signed_up" args:@{} callback:^(NSDictionary *result, NSError *error) {
            if ([result[@"success"] boolValue]) {
                [self gotPhonesOfFriendsOnSquawk:result[@"phones"]];
                [WSPersistentDictionary shared][@"SQLastFriendReload"] = [NSDate date];
            }
            reloadInProgress = NO;
        }];
    }
}

-(void)gotPhonesOfFriendsOnSquawk:(NSArray*)phones {
    NSSet* current = self.setOfPhoneNumbersOfFriendsOnSquawk.first;
    BOOL allFriendsAlreadyAdded = YES;
    for (NSString* phone in phones) {
        if (![current containsObject:phone]) {
            allFriendsAlreadyAdded = NO;
        }
    }
    if (allFriendsAlreadyAdded) return;
    
    [[[WSPersistentDictionary shared] getObjectForKey:@"SQPhoneNumbersOfFriendsOnSquawk" fallback:^id{
        return [NSMutableSet new];
    }] addObjectsFromArray:phones];
    [[WSPersistentDictionary shared] didUpdateValueForKey:@"SQPhoneNumbersOfFriendsOnSquawk"];
}

-(RACSignal*)setOfPhoneNumbersOfFriendsOnSquawk {
    return [[WSPersistentDictionary shared] signalForKey:@"SQPhoneNumbersOfFriendsOnSquawk"];
}

#pragma mark Squawk invitations
-(void)sendInvitesToUsersIfNecessary:(NSArray*)phones prompt:(NSString*)prompt {
    [SQAPI call:@"/which_users_not_signed_up" args:@{@"phones": phones} callback:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray* missingPhones = result[@"users_not_signed_up"];
            _phonesForInvitationPrompt = missingPhones;
            _invitationPrompt = prompt;
            NSArray* missingNames = [missingPhones.rac_sequence map:^id(id value) {
                return [SQThread nameForNumber:value];
            }].array;
            if (missingPhones.count > 0) {
                NSString* alert = nil;
                if (missingNames.count == 1) {
                    alert = [NSString stringWithFormat:NSLocalizedString(@"%@ isn't on Squawk.", @"[Person] isn't on Squawk."), missingNames.firstObject];
                } else {
                    alert = [NSString stringWithFormat:NSLocalizedString(@"%@ aren't on Squawk.", @"[Person1, Person2, and Person3] aren't on Squawk."), [missingNames combineStringsAsNaturalLanguage]];
                }
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Someone's missing out", @"") message:alert delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"Text an invite", nil];
                [alertView show];
            }
        });
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self sendInvitationMessage:_invitationPrompt toPhones:_phonesForInvitationPrompt];
    }
}
-(void)sendInvitationMessage:(NSString*)prompt toPhones:(NSArray*)phones {
    if (![MFMessageComposeViewController canSendText]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops", @"") message:NSLocalizedString(@"Looks like your device isn't set up to send messages.", @"") delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    _messageComposer = [[MFMessageComposeViewController alloc] init];
    _messageComposer.body = prompt;
    _messageComposer.recipients = phones;
    _messageComposer.messageComposeDelegate = self;
    [[AppDelegate window].rootViewController presentViewController:_messageComposer animated:YES completion:nil];
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    _messageComposer = nil;
}
+(NSString*)genericInvitationPrompt {
    return NSLocalizedString(@"Download Squawk so we can send instant voice messages. http://come.squawkwith.us", @"");
}
+(NSString*)receivedMessageInvitationPrompt {
    return NSLocalizedString(@"You've got a Squawk. Download the app to hear it. http://come.squawkwith.us", @"");
}

@end
