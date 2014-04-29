//
//  NPAddressBook.m
//  QuickCall
//
//  Created by Nate Parrott on 4/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "NPAddressBook.h"
#import "ConvenienceCategories.h"

void NPAddressBookRefDidChange(ABAddressBookRef addressBook,
                               CFDictionaryRef info,
                               void *context) {
    NPAddressBook* book = (__bridge NPAddressBook*)context;
    [book externalChangesDidOccur:(__bridge NSDictionary*)info];
}

const NSString* NPAddressBookDidChangeNotification = @"kNPAddressBookDidChangeNotification";

NPAddressBook* NPAddressBookShared = nil;

@implementation NPAddressBook

-(id)init {
    self = [super init];
    self.addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (!self.authorized) {
        ABAddressBookRequestAccessWithCompletion(self.addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [self externalChangesDidOccur:nil];
            }
        });
    }
    return self;
}
-(BOOL)authorized {
    return ABAddressBookGetAuthorizationStatus()==kABAuthorizationStatusAuthorized;
}
-(void)setAddressBookRef:(ABAddressBookRef)addressBookRef {
    _addressBookRef = addressBookRef;
    ABAddressBookRegisterExternalChangeCallback(addressBookRef, NPAddressBookRefDidChange, (__bridge void*)self);
}
-(void)dealloc {
    if (self.addressBookRef) {
        ABAddressBookUnregisterExternalChangeCallback(self.addressBookRef, NPAddressBookRefDidChange, (__bridge void*)self);
        CFRelease(self.addressBookRef);
    }
}
-(void)externalChangesDidOccur:(NSDictionary*)dict {
    [self reloadContacts];
    [[NSNotificationCenter defaultCenter] postNotificationName:(id)NPAddressBookDidChangeNotification object:self];
}
-(void)reloadContacts {
    void(^block)() = ^() {
        NSMutableDictionary* contactsForIDs = _contactsForIDs? _contactsForIDs.mutableCopy : [NSMutableDictionary new];
        
        NSMutableSet* nowUnusedContactIDs = [NSMutableSet setWithArray:contactsForIDs.allValues];
        
        NSArray* records = (__bridge id)ABAddressBookCopyArrayOfAllPeople(self.addressBookRef);
        
        NSMutableSet* recordIDsToSkip = [NSMutableSet new];
        NSArray* uniqueContacts = [records map:^id(id obj) {
            ABRecordRef record = (__bridge ABRecordRef)obj;
            if ([recordIDsToSkip containsObject:@(ABRecordGetRecordID(record))]) {
                return nil;
            }
            NPContact* contact = contactsForIDs[@(ABRecordGetRecordID(record))];
            if (!contact) contact = [NPContact new];
            contact.records = (__bridge_transfer id)ABPersonCopyArrayOfAllLinkedPeople(record);
            for (id rec in contact.records) {
                ABRecordRef record = (__bridge ABRecordRef)rec;
                [recordIDsToSkip addObject:@(ABRecordGetRecordID(record))];
            }
            [nowUnusedContactIDs removeObject:@(ABRecordGetRecordID(record))];
            return contact;
        }];
        for (NPContact* contact in uniqueContacts) {
            contactsForIDs[contact.recordID] = contact;
        }
        for (NSNumber* recordID in nowUnusedContactIDs) {
            [contactsForIDs removeObjectForKey:recordID];
        }
        @synchronized(self) {
            _contactsForIDs = contactsForIDs;
        }
    };
    if ([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
-(NSArray*)allContacts {
    if (!_contactsForIDs) {
        [self reloadContacts];
    }
    return _contactsForIDs.allValues;
}
+(void)getAuthorizedAddressBookWithCallback:(void(^)(NPAddressBook* book))callback {
	NPAddressBook* book = [NPAddressBook new];
	if (book.authorized) {
		callback(book);
	} else {
		ABAddressBookRequestAccessWithCompletion(book.addressBookRef, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(granted? book : nil);
            });
		});
	}
}
+(dispatch_queue_t)addressBookQueue {
    return dispatch_get_main_queue();
    /*static dispatch_queue_t q = 0;
    @synchronized(q) {
        if (!q) {
            q = dispatch_queue_create("Address book queue", 0);
        }
        return q;
    }*/
}

+(void)createContactWithName:(NSString*)name phone:(NSString*)phone info:(NSDictionary*)otherInfo callback:(void(^)(NPContact* contact))callback {
    [self getGlobalAddressBook:^(NPAddressBook *book) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!book) {
                callback(nil);
                return;
            }
            CFErrorRef err = NULL;
            ABRecordRef person = ABPersonCreate();
            
            NSArray* nameComps = [name componentsSeparatedByString:@" "];
            NSString *firstname = nil;
            NSString *lastname = nil;
            if (nameComps.count == 1) {
                firstname = nameComps.firstObject;
            } else if (nameComps.count > 1) {
                lastname = nameComps.lastObject;
                firstname = [[nameComps subarrayWithRange:NSMakeRange(0, nameComps.count-1)] componentsJoinedByString:@" "];
            }
            if (firstname) ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstname), &err);
            if (lastname) ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)(lastname), &err);
            
            ABMutableMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(phones, (__bridge CFTypeRef)(phone), kABPersonPhoneMainLabel, NULL);
            ABRecordSetValue(person, kABPersonPhoneProperty, phones, NULL);
            
            ABAddressBookAddRecord(book.addressBookRef, person, &err);
            
            ABAddressBookSave(book.addressBookRef, &err);
            
            NPContact* contact = [NPContact new];
            contact.records = (__bridge NSArray *)(ABPersonCopyArrayOfAllLinkedPeople(person));
            
            CFRelease(phones);
            CFRelease(person);
            
            [book externalChangesDidOccur:nil];
            callback(contact);
        });
    }];
}
#pragma mark ReactiveCocoa
+(void)startPopulatingContactsSignal {
    [self getGlobalAddressBook:^(NPAddressBook *book) {
        if (book) {
            [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:(id)NPAddressBookDidChangeNotification object:book] startWith:nil] subscribeNext:^(id x) {
                [[self contacts] sendNext:book.allContacts];
            }];
        }
    }];
}
+(RACReplaySubject*)contacts {
    static RACReplaySubject* subj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        subj =  [RACReplaySubject replaySubjectWithCapacity:1];
        [subj sendNext:nil];
    });
    return subj;
}
+(RACSignal*)contactsByPhoneNumber {
    static RACReplaySubject* signal = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signal = [RACReplaySubject replaySubjectWithCapacity:1];
        [[[self contacts] deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] subscribeNext:^(NSArray* contacts) {
            NSMutableDictionary* d = [NSMutableDictionary new];
            for (NPContact* contact in contacts) {
                for (NSString* num in contact.phoneNumbers) {
                    d[num] = contact;
                }
            }
            [signal sendNext:d];
        }];
    });
    return signal;
}
+(void)getGlobalAddressBook:(void(^)(NPAddressBook* book))callback {
    static NPAddressBook* addressBook = nil;
    
    if (!addressBook) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [NPAddressBook getAuthorizedAddressBookWithCallback:^(NPAddressBook *book) {
                addressBook = book;
                callback(addressBook);
            }];
        });
    } else {
        callback(addressBook);
    }
    
}

@end
