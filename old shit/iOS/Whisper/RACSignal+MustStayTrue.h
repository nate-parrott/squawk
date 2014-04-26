//
//  RACSignal+MustStayTrue.h
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <ReactiveCocoa.h>

@interface RACSignal (MustStayTrue)

-(RACSignal*)mustStayTrueFor:(NSTimeInterval)duration;

@end
