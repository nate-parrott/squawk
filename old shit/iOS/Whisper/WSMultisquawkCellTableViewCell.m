//
//  WSMultisquawkCellTableViewCell.m
//  Squawk
//
//  Created by Nate Parrott on 2/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSMultisquawkCellTableViewCell.h"
#import "WSPersistentDictionary.h"

NSString* WSShouldQuitMultisquawkMode = @"WSShouldQuitMultisquawkMode";

@implementation WSMultisquawkCellTableViewCell

-(NSArray*)phoneNumbers {
    NSSet* nums = [WSMultisquawkCellTableViewCell multisquawkSelectedPhoneNumbers];
    return nums.allObjects;
}

-(IBAction)endMultisquawkMode:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:WSShouldQuitMultisquawkMode object:nil];
}

+(NSMutableSet*)multisquawkSelectedPhoneNumbers {
    static NSMutableSet* set = nil;
    if (!set) {
        set = [NSMutableSet new];
    }
    return set;
}

@end
