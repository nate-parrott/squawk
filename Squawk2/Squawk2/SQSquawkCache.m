//
//  SQSquawkCache.m
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQSquawkCache.h"
#import "NPAddressBook.h"
#import "WSPersistentDictionary.h"
#import "SQAPI.h"
#import "NSData+HexDump.h"
#import "SQBackgroundTaskManager.h"
#import <NPReachability.h>
#import "SQFriendsOnSquawk.h"
#import "SQThread.h"

@interface SQSquawkCache () {
    NPReachability* _reachability;
    
    NSTimer* _timer;
}

@end

@implementation SQSquawkCache

+(SQSquawkCache*)shared {
    static SQSquawkCache* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [SQSquawkCache new];
    });
    return shared;
}
-(id)init {
    self = [super init];
    
    RAC(self, squawks) = [[WSPersistentDictionary shared] signalForKey:@"SQSquawkCache"];
    
    _reachability = [NPReachability sharedInstance];
    RACSignal* cameOnline = [[RACObserve(_reachability, currentlyReachable) filter:^BOOL(id value) {
        return [value boolValue];
    }] startWith:nil];
    RACSignal* appOpened = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillEnterForegroundNotification object:nil] startWith:nil];
    RACSignal* loginStatus = [SQAPI loginStatus];
    [[[RACSignal combineLatest:@[appOpened, loginStatus, cameOnline]] throttle:0.2] subscribeNext:^(id x) {
        [self fetch];
    }];
    
    [[RACObserve(self, squawks) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        [SQThread makeSureListenedSquawksAreKnownOnServer:x];
    }];
    
    NSTimeInterval reloadInterval = [AppDelegate.globalProperties[@"pollInterval"] doubleValue]? : 60;
    _timer = [NSTimer scheduledTimerWithTimeInterval:reloadInterval target:self selector:@selector(pollIfNeeded) userInfo:nil repeats:YES];
    
    
    return self;
}
+(void)dataUpdated {
    [[WSPersistentDictionary shared] didUpdateValueForKey:@"SQSquawkCache"];
}
-(void)fetch {
    if ([SQAPI currentPhone]) {
        self.fetchInProgress = YES;
        NSURL* url = [SQAPI urlForEndpoint:@"/squawks/recent" args:@{}];
        NSURLRequest* req = [NSURLRequest requestWithURL:url];
        [[SQBackgroundTaskManager shared] download:req withCallback:SQBackgroundTaskCallbackMake([SQSquawkCache class], @selector(fetchCompleted:), @"")];
    }
}
+(void)fetchCompleted:(NSDictionary*)info {
    NSURL* path = info[SQBackgroundTaskCallbackFileURLKey];
    if (path) {
        NSData* file = [NSData dataWithContentsOfURL:path];
        if (file) {
            NSDictionary* data = [NSJSONSerialization JSONObjectWithData:file options:0 error:nil];
            if (data && [data[@"success"] boolValue]) {
                for (NSDictionary* squawk in data[@"results"]) {
                    if (squawk[@"sender"]) {
                        [[SQFriendsOnSquawk shared] gotPhonesOfFriendsOnSquawk:@[squawk[@"sender"]]];
                    }
                }
                [SQSquawkCache shared].error = nil;
                [WSPersistentDictionary shared][@"SQSquawkCache"] = data[@"results"];
            } else if (data) {
                if ([data[@"error"] isEqualToString:@"bad_token"]) {
                    [SQAPI logOut];
                }
            }
        }
    } else if (info[SQBackgroundTaskCallbackErrorKey]) {
        [SQSquawkCache shared].error = info[SQBackgroundTaskCallbackErrorKey];
    }
    [SQSquawkCache shared].fetchInProgress = NO;
    // [[SQBackgroundTaskManager shared] completedBackgroundTaskCallback] is called by the main view controller reloader
}
+(NSString*)squawkAudioDir {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"SquawkAudio"];
}
-(NSString*)cachePathForSquawkWithID:(NSString*)squawkID {
    NSString* hexID = [[squawkID dataUsingEncoding:NSUTF8StringEncoding] asHexadecimal];
    NSString* cachedPath = [[SQSquawkCache squawkAudioDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", hexID]];
    return cachedPath;
}
-(void)preloadSquawkAudioWithID:(NSString*)squawkID {
    NSURLRequest* req = [NSURLRequest requestWithURL:[SQAPI urlForEndpoint:@"/squawks/serve" args:@{@"id": squawkID}]];
    [[SQBackgroundTaskManager shared] download:req withCallback:SQBackgroundTaskCallbackMake([SQSquawkCache class], @selector(squawkPreloadFinished:), squawkID)];
}
-(void)deleteCachesForSquawkWithID:(NSString*)squawkID {
    [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForSquawkWithID:squawkID] error:nil];
}
+(void)squawkPreloadFinished:(NSDictionary*)info {
    NSURL* fileURL = info[SQBackgroundTaskCallbackFileURLKey];
    NSString* squawkID = info[SQBackgroundTaskCallbackUserInfoKey];
    if (fileURL && squawkID) {
        DBLog(@"preloaded squawk to %@", [[SQSquawkCache shared] cachePathForSquawkWithID:squawkID]);
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self squawkAudioDir]]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[self squawkAudioDir] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:[[SQSquawkCache shared] cachePathForSquawkWithID:squawkID]] error:nil];
    }
    [[SQBackgroundTaskManager shared] completedBackgroundTaskCallback];
}
-(void)getDataForSquawk:(NSDictionary*)squawk callback:(void(^)(NSData* data, NSError* error))callback {

    NSString* cachedPath = [self cachePathForSquawkWithID:squawk[@"_id"]];
    DBLog(@"Looking for preload at %@", cachedPath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedPath]) {
        DBLog(@"found");
        callback([NSData dataWithContentsOfFile:cachedPath], nil);
    } else {
        DBLog(@"not found");
        [SQAPI getData:@"/squawks/serve" args:@{@"id": squawk[@"_id"]} callback:^(NSData *data, NSError *error) {
            callback(data, error);
        }];
    }
}
-(void)pollIfNeeded {
    if (![AppDelegate pushNotificationsEnabled] && [SQAPI currentPhone] && [UIApplication sharedApplication].applicationState==UIApplicationStateActive) {
        [self fetch];
    }
}

@end
