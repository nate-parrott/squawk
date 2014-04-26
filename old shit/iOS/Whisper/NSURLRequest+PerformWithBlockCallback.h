//
//  NSURLRequest+PerformWithBlockCallback.h
//  HNClient
//
//  Created by Nate Parrott on 2/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSURLRequestTask;

@interface NSURLRequest (PerformWithBlockCallback)

typedef void(^NSURLRequestCallback)(NSData*, NSError*);

-(NSURLRequestTask*)performRequestWithCallback:(NSURLRequestCallback)callback;
-(NSURLRequestTask*)performRequestWithCallback:(NSURLRequestCallback)callback maximumSize:(long)maxBytes;

@end

@interface NSURLRequestTask : NSObject <NSURLConnectionDataDelegate> {
@private
    NSURLConnection* _connection;
    NSMutableData* _data;
    NSURLRequestCallback _callback;
}
-(id)initWithRequest:(NSURLRequest*)req callback:(NSURLRequestCallback)callback;
@property long maxBytes;
-(void)cancel;

@end
