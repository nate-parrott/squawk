//
//  SQAPI.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQAPI.h"
#import "NSData+HexDump.h"
#import "NSString+PercentEscaping.h"
#import "NSString+TempFilePath.h"
#import "SQBackgroundTaskManager.h"
#import "WSPersistentDictionary.h"

const NSInteger SQLoginBadSecretError = 123;

NSString* SQResponseData  = @"SQResponseData";

@implementation SQAPI

+(void)logInWithSecret:(NSString*)secret callback:(void(^)(BOOL success, NSError* error))callback {
    [self logOut];
    [self call:@"/make_token" args:@{@"secret": secret} callback:^(NSDictionary *result, NSError *error) {
        if (result && !error) {
            if ([result[@"success"] boolValue]) {
                [AppDelegate trackEventWithCategory:@"login" action:@"logged_in" label:nil value:nil];
                [[NSUserDefaults standardUserDefaults] setObject:result[@"phone"] forKey:@"PhoneNumber"];
                [[NSUserDefaults standardUserDefaults] setObject:result[@"token"] forKey:@"AuthToken"];
                callback(YES, nil);
            } else {
                callback(NO, [NSError errorWithDomain:SQErrorDomain code:SQLoginBadSecretError userInfo:nil]);
            }
        } else {
            callback(NO, error);
        }
    }];
}
+(void)logOut {
    NSString* pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"UploadedPushToken"];
    if (pushToken) {
        [SQAPI call:@"/unregister_push_token" args:@{@"push_token": pushToken, @"type": @"ios"} callback:^(NSDictionary *result, NSError *error) {
            
        }];
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AuthToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PhoneNumber"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UploadedPushToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UploadedLanguages"];
}
+(NSString*)currentPhone {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"PhoneNumber"];
}
+(NSString*)authToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"AuthToken"];
}

+(NSURL*)urlForEndpoint:(NSString*)endpoint args:(NSDictionary*)args {
    NSMutableDictionary* params = args.mutableCopy;
    if ([self authToken]) params[@"token"] = [self authToken];
    NSString* argString = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:0 error:nil] encoding:NSUTF8StringEncoding] percentEscaped];
    NSString* url  = [NSString stringWithFormat:@"%@%@?args=%@", API_ROOT, endpoint, argString];
    return [NSURL URLWithString:url];
}
+(void)call:(NSString*)endpoint args:(NSDictionary*)args callback:(SQAPICallback)callback {
    NSURLRequest* req = [NSURLRequest requestWithURL:[self urlForEndpoint:endpoint args:args]];
    DBLog(@"%@", req.URL.absoluteString);
    [self performRequest:req withCallback:callback];
}
+(void)performRequest:(NSURLRequest*)req withCallback:(SQAPICallback)callback {
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"API error: GET %@", req.URL.absoluteString);
            NSLog(@"Error: %@", error.localizedDescription);
            callback(nil, error);
            return;
        }
        NSDictionary* responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([responseObject[@"error"] isEqualToString:@"bad_token"]) {
            [self logOut];
            callback(nil, nil);
            return;
        }
        callback(responseObject, nil);
    }] resume];
}
+(void)getData:(NSString*)endpoint args:(NSDictionary*)args callback:(void(^)(NSData* data, NSError* error))callback {
    NSURLRequest* req = [NSURLRequest requestWithURL:[self urlForEndpoint:endpoint args:args]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"API error: GET %@", req.URL.absoluteString);
            JSLog(args);
            NSLog(@"Error: %@", error.localizedDescription);
            callback(nil, error);
            return;
        } else {
            callback(data, nil);
        }
    }] resume];
}
+(void)post:(NSString*)endpoint args:(NSDictionary*)args data:(NSData*)postData callback:(SQAPICallback)callback {
    [self post:endpoint args:args data:postData contentType:@"application/octet-stream" callback:callback];
}
+(void)post:(NSString*)endpoint args:(NSDictionary*)args data:(NSData*)postData contentType:(NSString*)mime callback:(SQAPICallback)callback {
    NSURL* url = [self urlForEndpoint:endpoint args:args];
    NSMutableURLRequest* req = [[NSURLRequest requestWithURL:url] mutableCopy];
    req.HTTPMethod = @"POST";
    req.HTTPBody = postData;
    [req setValue:mime forHTTPHeaderField:@"Content-Type"];
    [self performRequest:req withCallback:callback];
}
+(void)postInBackground:(NSString*)endpoint args:(NSDictionary*)args file:(NSURL*)file callback:(SQBackgroundTaskCallback)callback {
    NSURL* url = [self urlForEndpoint:endpoint args:args];
    NSMutableURLRequest* req = [[NSURLRequest requestWithURL:url] mutableCopy];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    [[SQBackgroundTaskManager shared] upload:req fromFile:file withCallback:callback];
}
+(RACSignal*)loginStatus {
    return [[[NSUserDefaults standardUserDefaults] rac_valuesForKeyPath:@"AuthToken" observer:nil] map:^id(id value) {
        return @(value!=nil);
    }];
}
+(void)registerPushToken:(NSData*)pushToken {
    if ([self authToken]) {
        NSString* hex = [pushToken asHexadecimal];
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"UploadedPushToken"] isEqualToString:hex]) {
            NSString* platformType = @"ios";
#ifdef DEBUG
      platformType = @"ios-dev";
#endif
            [self call:@"/register_push_token" args:@{@"push_token": hex, @"type": platformType} callback:^(NSDictionary *result, NSError *error) {
                if (result && [result[@"success"] boolValue]) {
                    [[NSUserDefaults standardUserDefaults] setObject:hex forKey:@"UploadedPushToken"];
                }
            }];
        }
    }
}
#pragma mark User prefs
+(NSDictionary*)userPrefs {
    return [[WSPersistentDictionary shared] getObjectForKey:@"UserPrefs" fallback:^id{
        return @{};
    }];
}
+(void)updateUserPrefs:(NSDictionary*)prefs {
    NSData* oldPayload = [NSJSONSerialization dataWithJSONObject:[self userPrefs] options:0 error:nil];
    NSData* newPayload = [NSJSONSerialization dataWithJSONObject:prefs options:0 error:nil];
    if (![newPayload isEqualToData:oldPayload] || [[NSUserDefaults standardUserDefaults] boolForKey:@"UserPrefsNeedUpload"]) {
        [WSPersistentDictionary shared][@"UserPrefs"] = prefs;
        [self post:@"/update_prefs" args:@{} data:newPayload contentType:@"application/json" callback:^(NSDictionary *result, NSError *error) {
            BOOL done = ([result[@"success"] boolValue] && !error);
            [[NSUserDefaults standardUserDefaults] setBool:!done forKey:@"UserPrefsNeedUpload"];
        }];
    }
}

@end
