//
//  NPAddressBook.h
//  QuickCall
//
//  Created by Nate Parrott on 4/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPContact.h"
#import <AddressBook/AddressBook.h>
#import "WSAppDelegate.h"

const NSString* NPAddressBookDidChangeNotification;

@interface NPAddressBook : NSObject {
    NSMutableDictionary* _contactsForIDs;
}

//+(void)getAddressBook:(void(^)(NPAddressBook*))callback;

@property(nonatomic) ABAddressBookRef addressBookRef;
-(NSArray*)allContacts;
-(void)externalChangesDidOccur:(NSDictionary*)dict;
-(BOOL)authorized;

+(void)getAuthorizedAddressBookWithCallback:(void(^)(NPAddressBook* book))callback;

+(dispatch_queue_t)addressBookQueue;

+(void)createContactWithName:(NSString*)name phone:(NSString*)phone info:(NSDictionary*)otherInfo callback:(WSEmptyCallback)callback;

@end
