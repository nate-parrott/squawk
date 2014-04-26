//
//  UITextField+PopulateSlowly.h
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (PopulateSlowly)

-(void)populateSlowlyWithText:(NSString*)newText duration:(NSTimeInterval)duration;

@end
