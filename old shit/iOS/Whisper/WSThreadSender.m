//
//  WSThreadSender.m
//  Squawk
//
//  Created by Nate Parrott on 2/22/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSThreadSender.h"
#import <ReactiveCocoa.h>
#import "ConvenienceCategories.h"

@implementation WSThreadSender

-(NSString*)displayName {
    return [[[[[[self members] rac_sequence] filter:^BOOL(id value) {
        return ![[value objectId] isEqual:[PFUser currentUser].objectId];
    }] map:^id(id participant) {
        for (NPContact* contact in self.contacts) {
            if ([contact.phoneNumbers containsObject:[participant valueForKey:@"username"]]) {
                return [contact shortDisplayLabel];
            }
        }
        return [participant valueForKey:@"nickname"];
    }] array] componentsJoinedByString:@", "];
}
-(NSArray*)phoneNumbers {
    return [self.members.allObjects map:^id(id obj) {
        return [obj valueForKey:@"username"];
    }];
}
-(NSString*)nickname {
    return @"";
}
-(BOOL)isRegistered {
    return YES;
}
-(NSString*)preferredPhoneNumber {
    return nil;
}
-(NSArray*)phoneNumbersToSendTo {
    return [[[self members] allObjects] map:^id(id obj) {
        return [obj valueForKey:@"username"];
    }];
}
-(NSArray*)unread {
    return [[super unread] map:^id(id obj) {
        return [[[obj valueForKey:@"sender"] objectId] isEqualToString:[PFUser currentUser].objectId]? nil : obj;
    }];
}
-(NSSet*)members {
    NSMutableSet* seenUsernames = [NSMutableSet new];
    NSMutableSet* users = [NSMutableSet new];
    for (PFObject* msg in self.messages) {
        for (PFUser* user in [msg valueForKey:@"threadMembers"]) {
            if ([seenUsernames containsObject:user.objectId]) continue;
            [seenUsernames addObject:user.objectId];
            [users addObject:user];
        }
    }
    return users;
}
-(BOOL)isGroupThread {
    return YES;
}

@end
