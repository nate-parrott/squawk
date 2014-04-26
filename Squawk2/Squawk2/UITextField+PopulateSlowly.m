//
//  UITextField+PopulateSlowly.m
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "UITextField+PopulateSlowly.h"

@implementation UITextField (PopulateSlowly)

-(void)populateSlowlyWithText:(NSString*)newText duration:(NSTimeInterval)duration {
    int changes = self.text.length + newText.length;
    if (changes <= 1) {
        self.text = newText;
        return;
    }
    __block BOOL clearedYet = NO;
    [[[RACSignal interval:duration/changes onScheduler:[RACScheduler mainThreadScheduler]] take:changes] subscribeNext:^(id x) {
        if (self.text.length==0) {
            clearedYet = YES;
        }
        if (!clearedYet) {
            self.text = [self.text substringToIndex:self.text.length-1];
        } else {
            self.text = [newText substringToIndex:self.text.length+1];
        }
    }];
}

@end
