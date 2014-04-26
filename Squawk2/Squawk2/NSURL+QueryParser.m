//
//  NSURL+QueryParser.m
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSURL+QueryParser.h"

@implementation NSURL (QueryParser)

-(NSDictionary *)queryDictionary
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[self query] componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) continue;
        [params setObject:[[parts objectAtIndex:1] stringByRemovingPercentEncoding] forKey:[parts objectAtIndex:0]];
    }
    return params;
}

@end
