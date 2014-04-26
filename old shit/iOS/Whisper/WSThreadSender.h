//
//  WSThreadSender.h
//  Squawk
//
//  Created by Nate Parrott on 2/22/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSMessageSender.h"

@interface WSThreadSender : WSMessageSender

-(NSSet*)members; // PFUsers, including self

@property(strong)NSArray* contacts;

@end
