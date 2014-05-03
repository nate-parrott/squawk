//
//  SQAPI.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQBackgroundTaskManager.h"

const NSInteger SQLoginBadSecretError;

NSString* SQResponseData;

typedef void (^SQAPICallback)(NSDictionary* result, NSError* error);

@interface SQAPI : NSObject

+(void)logInWithSecret:(NSString*)secret callback:(void(^)(BOOL success, NSError* error))callback;
+(void)logOut;
+(NSString*)currentPhone;
+(RACSignal*)loginStatus;

+(void)call:(NSString*)endpoint args:(NSDictionary*)args callback:(SQAPICallback)callback;
+(void)getData:(NSString*)endpoint args:(NSDictionary*)args callback:(void(^)(NSData* data, NSError* error))callback;
+(void)post:(NSString*)endpoint args:(NSDictionary*)args data:(NSData*)postData callback:(SQAPICallback)callback;
+(void)post:(NSString*)endpoint args:(NSDictionary*)args data:(NSData*)postData contentType:(NSString*)mime callback:(SQAPICallback)callback;
+(void)postInBackground:(NSString*)endpoint args:(NSDictionary*)args file:(NSURL*)file callback:(SQBackgroundTaskCallback)callback;
+(NSURL*)urlForEndpoint:(NSString*)endpoint args:(NSDictionary*)args;

+(void)registerPushToken:(NSData*)pushToken;

+(NSDictionary*)userPrefs;
+(void)updateUserPrefs:(NSDictionary*)pref;

@end
