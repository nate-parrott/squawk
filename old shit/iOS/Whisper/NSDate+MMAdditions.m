//
//  NSDate+MMAdditions.m
//  Moments
//
//  Created by Nate Parrott on 1/14/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSDate+MMAdditions.h"

@implementation NSDate (MMAdditions)

-(NSDate*)roundToDay {
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    return [cal dateFromComponents:comps];
}
-(NSString*)dayString {
    NSDateFormatter* f = [[NSDateFormatter alloc] init];
    f.dateStyle = NSDateFormatterMediumStyle;
    f.timeStyle = NSDateFormatterNoStyle;
    return [f stringFromDate:self];
}

@end
