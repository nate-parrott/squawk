//
//  WSAppDelegate+GlobalUIExtensions.h
//  Squawk
//
//  Created by Nate Parrott on 2/13/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSAppDelegate.h"

@interface WSAppDelegate (GlobalUIExtensions)

-(void)toast:(NSString*)message;
-(void)showCheckmarkAnimationStartingFromButton:(UIButton*)sourceButton;

@end
