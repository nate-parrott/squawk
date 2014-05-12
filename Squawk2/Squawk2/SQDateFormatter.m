//
//  SQDateFormatter.m
//  Squawk2
//
//  Created by Nate Parrott on 5/7/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQDateFormatter.h"
#import <TFGRelativeDateFormatter.h>

@implementation SQDateFormatter

+(NSString*)formatDate:(NSDate*)date {
    if ([[NSLocale preferredLanguages].firstObject isEqualToString:@"en"]) {
        return [[TFGRelativeDateFormatter sharedFormatter] stringForDate:date];
    } else {
        NSDateFormatter* formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        [formatter setDoesRelativeDateFormatting:YES];
        return [formatter stringFromDate:date];
    }
}

@end
