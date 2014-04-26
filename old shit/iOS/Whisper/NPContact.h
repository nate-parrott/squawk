//
//  NPContact.h
//  QuickCall
//
//  Created by Nate Parrott on 4/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface NPContact : NSObject {
    ABRecordID _recordIDCache;
    NSArray* _cachedSearchFields;
    NSArray* _phoneNumbers;
}

-(ABRecordRef)record;
@property(strong,nonatomic)NSArray* records;

-(NSNumber*)recordID;

-(NSString*)name;
-(id)getProperty:(ABPropertyID)property;
-(NSArray*)valuesForProperty:(ABPropertyID)property;
-(UIImage*)image;
-(NSArray*)phoneNumbers;
-(NSString*)mobileNumber;
-(NSString*)displayLabel;
-(NSString*)shortDisplayLabel;

@property(strong)NSMutableArray* messages;

+(NSString*)normalizePhone:(NSString*)phoneNum;

@end
