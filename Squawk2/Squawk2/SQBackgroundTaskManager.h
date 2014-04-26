//
//  SQBackgroundTaskManager.h
//  Squawk2
//
//  Created by Nate Parrott on 3/15/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString* SQBackgroundTaskCallback;
SQBackgroundTaskCallback SQBackgroundTaskCallbackMake(Class cls, SEL classMethod, NSString* userInfo);
// `classMethod` must take a dictionary
NSString *const SQBackgroundTaskCallbackErrorKey;
NSString *const SQBackgroundTaskCallbackUserInfoKey;
NSString *const SQBackgroundTaskCallbackFileURLKey;


@interface SQBackgroundTaskManager : NSObject

+(SQBackgroundTaskManager*)shared;

-(void)launchedWithCompletionHandler:(void(^)())handler;
-(void)completedBackgroundTaskCallback;

-(void)download:(NSURLRequest*)req withCallback:(SQBackgroundTaskCallback)callback;
-(void)upload:(NSURLRequest*)req fromFile:(NSURL*)fileURL withCallback:(SQBackgroundTaskCallback)callback;

@end
