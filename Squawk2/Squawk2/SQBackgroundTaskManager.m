//
//  SQBackgroundTaskManager.m
//  Squawk2
//
//  Created by Nate Parrott on 3/15/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQBackgroundTaskManager.h"

NSString *const SQBackgroundTaskCallbackErrorKey = @"SQBackgroundTaskCallbackErrorKey";
NSString *const SQBackgroundTaskCallbackUserInfoKey = @"SQBackgroundTaskCallbackUserInfoKey";
NSString *const SQBackgroundTaskCallbackFileURLKey = @"SQBackgroundTaskCallbackFileURLKey";

SQBackgroundTaskCallback SQBackgroundTaskCallbackMake(Class cls, SEL classMethod, NSString* userInfo) {
    return [NSString stringWithFormat:@"%@.%@.%@", NSStringFromClass(cls), NSStringFromSelector(classMethod), userInfo];
}

void SQBackgroundTaskInvokeCallback(SQBackgroundTaskCallback callback, NSURL* fileURL, NSError* error) {
    NSArray* parts = [callback componentsSeparatedByString:@"."];
    Class cls = NSClassFromString(parts[0]);
    SEL method = NSSelectorFromString(parts[1]);
    NSString* userInfo = parts[2];
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    if (error) dict[SQBackgroundTaskCallbackErrorKey] = error;
    if (fileURL) dict[SQBackgroundTaskCallbackFileURLKey] = fileURL;
    if (userInfo) dict[SQBackgroundTaskCallbackUserInfoKey] = userInfo;
    [cls performSelector:method withObject:dict];
}

@interface SQBackgroundTaskManager () <NSURLSessionDelegate, NSURLSessionDownloadDelegate> {
    int _unfinishedBackgroundTaskCallbacks;
}

@property(strong)NSURLSession *backgroundSession, *foregroundSession;
@property(strong)void (^backgroundSessionCompletionHandler)();
@property BOOL doneDeliveringBackgroundEvents;

@end


@implementation SQBackgroundTaskManager

+(SQBackgroundTaskManager*)shared {
    static SQBackgroundTaskManager* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [SQBackgroundTaskManager new];
    });
    return shared;
}
-(id)init {
    self = [super init];
    NSURLSessionConfiguration* conf = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.nateparrott.Squawk2.BackgroundTaskManager"];
    conf.allowsCellularAccess = YES;
    self.backgroundSession = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    return self;
}
-(void)launchedWithCompletionHandler:(void(^)())handler {
    DBLog(@"launched");
    self.backgroundSessionCompletionHandler = handler;
    self.doneDeliveringBackgroundEvents = NO;
    _unfinishedBackgroundTaskCallbacks = 0;
}
#pragma mark API
-(NSString*)callbackKeyForTask:(NSURLSessionTask*)task {
    return [NSString stringWithFormat:@"SQBackgroundTask-%lu", (unsigned long)task.taskIdentifier];
}
-(NSURLSession*)preferredSession {
    return self.backgroundSession;
}
-(void)download:(NSURLRequest*)req withCallback:(SQBackgroundTaskCallback)callback {
    NSURLSessionDownloadTask* task = [[self preferredSession] downloadTaskWithRequest:req];
    [[NSUserDefaults standardUserDefaults] setObject:callback forKey:[self callbackKeyForTask:task]];
    [task resume];
}
-(void)upload:(NSURLRequest*)req fromFile:(NSURL*)fileURL withCallback:(SQBackgroundTaskCallback)callback {
    NSURLSessionUploadTask* task = [[self preferredSession] uploadTaskWithRequest:req fromFile:fileURL];
    [[NSUserDefaults standardUserDefaults] setObject:callback forKey:[self callbackKeyForTask:task]];
    [task resume];
}
#pragma mark Delegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    _unfinishedBackgroundTaskCallbacks++;
    SQBackgroundTaskCallback callback = [[NSUserDefaults standardUserDefaults] objectForKey:[self callbackKeyForTask:downloadTask]];
    SQBackgroundTaskInvokeCallback(callback, location, nil);
    [self callBackgroundHandlerIfPossible];
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        // notify the download delegate of the failure
        _unfinishedBackgroundTaskCallbacks++;
        SQBackgroundTaskCallback callback = [[NSUserDefaults standardUserDefaults] objectForKey:[self callbackKeyForTask:task]];
        if (callback) {
            SQBackgroundTaskInvokeCallback(callback, nil, error);
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self callbackKeyForTask:task]];
        } else {
            [self completedBackgroundTaskCallback];
        }
    }
}
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    
}
-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    self.doneDeliveringBackgroundEvents = YES;
    [self callBackgroundHandlerIfPossible];
}
-(void)completedBackgroundTaskCallback {
    if (_unfinishedBackgroundTaskCallbacks>0) {
        _unfinishedBackgroundTaskCallbacks--;
    }
    [self callBackgroundHandlerIfPossible];
}
-(void)callBackgroundHandlerIfPossible {
    //DBLog(@"unfinished: %i; delivered: %u; handler: %u", _unfinishedBackgroundTaskCallbacks, self.doneDeliveringBackgroundEvents, !!self.backgroundSessionCompletionHandler);
    if (self.backgroundSessionCompletionHandler && self.doneDeliveringBackgroundEvents && _unfinishedBackgroundTaskCallbacks==0) {
        DBLog(@"end bg");
        self.backgroundSessionCompletionHandler();
        self.backgroundSessionCompletionHandler = nil;
        self.doneDeliveringBackgroundEvents = NO;
    }
}

@end
