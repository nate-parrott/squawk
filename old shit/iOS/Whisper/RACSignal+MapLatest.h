//
//  RACSignal+MapLatest.h
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "RACSignal.h"

@interface RACSignal (MapLatest)

-(RACSignal*)mapLatest:(id(^)(id value))block;

@end
