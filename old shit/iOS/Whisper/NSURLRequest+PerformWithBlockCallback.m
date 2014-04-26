//
//  NSURLRequest+PerformWithBlockCallback.m
//  HNClient
//
//  Created by Nate Parrott on 2/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURLRequest+PerformWithBlockCallback.h"

@implementation NSURLRequestTask
@synthesize maxBytes=_maxBytes;

+(NSMutableArray*)ongoingTasks {
    static NSMutableArray* tasks = nil;
    if (!tasks) {
        tasks = [NSMutableArray new];
    }
    return tasks;
}

-(id)initWithRequest:(NSURLRequest*)req callback:(NSURLRequestCallback)callback {
    self = [super init];
    
    _callback = [callback copy];
        
    _connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [_connection start];
    
    @synchronized([NSURLRequestTask ongoingTasks]) {
        [[NSURLRequestTask ongoingTasks] addObject:self];
    }
    
    return self;
}
-(void)cancel {
    [_connection cancel];
    [self done];
}
-(void)done {
    @synchronized([NSURLRequestTask ongoingTasks]) {
        [[NSURLRequestTask ongoingTasks] removeObject:self];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!_data) {
        _data = [NSMutableData dataWithData:data];
    } else {
        [_data appendData:data];
    }
    if (self.maxBytes!=0 && _data.length >= _maxBytes) {
        _callback(_data, nil);
        [self done];
    }
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _callback(nil, error);
    [self done];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    _callback(_data, nil);
    [self done];
}

@end

@implementation NSURLRequest (PerformWithBlockCallback)

-(NSURLRequestTask*)performRequestWithCallback:(NSURLRequestCallback)callback {
    return [[NSURLRequestTask alloc] initWithRequest:self callback:callback];
}
-(NSURLRequestTask*)performRequestWithCallback:(NSURLRequestCallback)callback maximumSize:(long)maxBytes {
    NSURLRequestTask* task = [[NSURLRequestTask alloc] initWithRequest:self callback:callback];
    task.maxBytes = maxBytes;
    return task;
}

@end
