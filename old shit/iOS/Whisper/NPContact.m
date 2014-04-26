//
//  NPContact.m
//  QuickCall
//
//  Created by Nate Parrott on 4/29/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "NPContact.h"
#import "ConvenienceCategories.h"


@implementation NPContact

-(ABRecordRef)record {
    return (__bridge ABRecordRef)self.records[0];
}
-(NSString*)name {
    CFTypeRef name = ABRecordCopyCompositeName(self.record);
    return (__bridge_transfer id)name;
}
-(id)getProperty:(ABPropertyID)property {
    NSArray* vals = [self valuesForProperty:property];
    return vals.count>0? vals[0] : nil;
}
-(NSArray*)valuesForProperty:(ABPropertyID)property {
    NSMutableArray* values = [NSMutableArray new];
    for (id rec in self.records) {
        ABRecordRef record = (__bridge ABRecordRef)rec;
        id value = CFBridgingRelease(ABRecordCopyValue(record, property));
        if (value) [values addObject:value];
    }
    return values;
}
-(NSArray*)phoneNumbers {
    if (!_phoneNumbers) {
        NSMutableArray* allNumbers = [NSMutableArray new];
        for (id nums in [self valuesForProperty:kABPersonPhoneProperty]) {
            ABMultiValueRef phoneNumbersMultiValue = (__bridge ABMultiValueRef)nums;
            NSArray* phoneNumbers = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(phoneNumbersMultiValue));
            phoneNumbers = [phoneNumbers map:^id(id obj) {
                NSString* num = obj;
                return [NPContact normalizePhone:num];
            }];
            [allNumbers addObjectsFromArray:phoneNumbers];
        }
        _phoneNumbers = allNumbers;
    }
    return _phoneNumbers;
}
-(NSString*)phoneNumberForLabel:(CFStringRef)targetLabel {
    for (id nums in [self valuesForProperty:kABPersonPhoneProperty]) {
        ABMultiValueRef phoneNumbersMultiValue = (__bridge ABMultiValueRef)nums;
        NSArray* phoneNumbers = CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(phoneNumbersMultiValue));
        for (int i=0; i<phoneNumbers.count; i++) {
            NSString* num = phoneNumbers[i];
            CFStringRef label = ABMultiValueCopyLabelAtIndex(phoneNumbersMultiValue, i);
            if (!label) continue;
            if (CFStringCompare(label, targetLabel, 0)==0) {
                CFRelease(label);
                return num;
            }
            CFRelease(label);
        }
    }
    return nil;
}
-(NSString*)mobileNumber {
    NSString* num = [self phoneNumberForLabel:kABPersonPhoneIPhoneLabel]? : [self phoneNumberForLabel:kABPersonPhoneMobileLabel]? : [self phoneNumbers].firstObject;
    return [NPContact normalizePhone:num];
}
+(NSString*)normalizePhone:(NSString*)phoneNum {
    NSString* cleanedNum = [[phoneNum componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
    if (cleanedNum.length==10) {
        cleanedNum = [@"1" stringByAppendingString:cleanedNum];
    }
    return cleanedNum;
}
-(UIImage*)image {
    for (id rec in self.records) {
        NSData* data = (id)CFBridgingRelease(ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)rec, kABPersonImageFormatThumbnail));
        if (data) return [UIImage imageWithData:data];
    }
    return nil;
}
-(NSNumber*)recordID {
    return @(ABRecordGetRecordID(self.record));
}
-(NSString*)displayLabel {
    if (self.name) {
        return self.name;
    } else if ([self getProperty:kABPersonOrganizationProperty]) {
        return [self getProperty:kABPersonOrganizationProperty];
    } else if ([self mobileNumber]) {
        return self.phoneNumbers.firstObject;
    } else {
        return nil;
    }
}
-(NSString*)shortDisplayLabel {
    return [[self.displayLabel componentsSeparatedByString:@" "] firstObject];
}
-(NSArray*)searchableFields {
    if (!_cachedSearchFields) {
        NSMutableArray* fields = [NSMutableArray new];
        ABPropertyID fieldsToFilter[] = {kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonFirstNamePhoneticProperty, kABPersonLastNamePhoneticProperty, kABPersonMiddleNameProperty, kABPersonNicknameProperty, kABPersonJobTitleProperty, kABPersonOrganizationProperty};
        for (int i=0; i<sizeof(fieldsToFilter)/sizeof(fieldsToFilter[0]); i++) {
            NSString* val = [self getProperty:fieldsToFilter[i]];
            if (val) [fields addObject:val];
        }
        if (self.name)
            [fields addObject:self.name];
        _cachedSearchFields = fields;
    }
    return _cachedSearchFields;
}
-(NSComparisonResult)compare:(id)other {
    return [self.name compare:[other name]];
}

@end
