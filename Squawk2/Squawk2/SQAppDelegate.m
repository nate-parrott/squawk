//
//  SQAppDelegate.m
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "SQAppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "WSToastNotificationView.h"
#import "SQFriendsOnSquawk.h"
#import "SQAPI.h"
#import "WSEarSensor.h"
#import "SQMainViewController.h"
#import "WSContactBoost.h"
#import "SQSquawkCache.h"
#import "SQTheme.h"
#import <Crashlytics/Crashlytics.h>
#import <GAI.h>
#import <GAIDictionaryBuilder.h>
#import "SQAudioFiles.h"
//#import <Helpshift.h>
#import "SQBackgroundTaskManager.h"
#import "WSPersistentDictionary.h"
#import "SQMessageViewController.h"
#import "NSURL+QueryParser.h"
#import "SQThreadMakerViewController.h"
#import "UIFont+OverrideSystemFont.h"

NSString* SQReceivedSquawkNotification = @"SQReceivedSquawkNotification";
NSString* SQPushSetupStatusChangedNotification = @"SQPushSetupStatusChangedNotification";
NSString* SQDidOpenMessageNotification = @"SQDidOpenMessageNotification";
NSString* SQPromptAddFriend = @"SQPromptAddFriend";

void JSLog(id jsonObj) {
    NSString* s =  [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObj options:0 error:0] encoding:NSUTF8StringEncoding];
    DBLog(@"%@", s);
}

NSString* SQErrorDomain = @"SQErrorDomain";

@implementation SQAppDelegate

#pragma mark App

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[NSUserDefaults standardUserDefaults] setDouble:BUILD_NUM forKey:@"LastLaunchedBuild"];
    
    [Crashlytics startWithAPIKey:@"c00a274f2c47ad5ee89b17ccb2fdb86e8d1fece8"];
    
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelWarning];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-47910043-3"];
    
    //[Helpshift installForApiKey:@"51e4c98d95cfbf0b3e22b90537203f26" domainName:@"squawk.helpshift.com" appID:@"squawk_platform_20140227180649929-134e795f46f5dc2"];
    
    [SQFriendsOnSquawk shared]; // initialize it
    [self setupAudio];
    [SQTheme apply];
    
    [self setupGlobalProperties];
    
    [self.window makeKeyAndVisible];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] startWith:nil] subscribeNext:^(id x) {
        // on app open:
        [self trackEventWithCategory:@"usage" action:@"opened_app" label:nil value:nil];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LogOut"]) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"LogOut"];
            [SQAPI logOut];
        }
    }];
    
    [SQAudioFiles load];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //NSLog(@"background");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //NSLog(@"foreground");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"LaunchCount"]+1 forKey:@"LaunchCount"];
    int launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"LaunchCount"];
    if (launchCount == 4 || launchCount == 70) {
        [WSContactBoost boostPhoneNumber:@"00000000001"];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
#pragma mark Audio
-(void)setupAudio {
    RACSignal* authorized = [[NSNotificationCenter defaultCenter] rac_addObserverForName:SQMicrophoneStatusGranted object:nil];
    RACSignal* earStateChanged = RACObserve([WSEarSensor shared], isRaisedToEar);
    RACSignal* appBecameActive = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] startWith:nil];
    [[[RACSignal combineLatest:@[appBecameActive, earStateChanged, authorized]] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        AVAudioSession* session = [AVAudioSession sharedInstance];
        AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetooth;
        if (![WSEarSensor shared].isRaisedToEar) {
            options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
        }
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:nil];
        [session setActive:YES error:nil];
    }];
}
#pragma mark Push notifications
-(void)setupPushNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
}
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:SQPushSetupStatusChangedNotification object:nil];
    self.registeredForPushNotifications = NO;
}
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [SQAPI registerPushToken:deviceToken];
    self.registeredForPushNotifications = YES;
}
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if ([userInfo[@"type"] isEqualToString:@"message"]) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SQDidOpenMessageNotification object:nil];
        }
        [[SQSquawkCache shared] fetch];
        [[SQSquawkCache shared] preloadSquawkAudioWithID:userInfo[@"squawk_id"]];
        completionHandler(UIBackgroundFetchResultNewData);
    } else if ([userInfo[@"type"] isEqualToString:@"friend_joined"]) {
        NSString* phone = userInfo[@"phone"];
        if (phone) {
            [WSContactBoost boostPhoneNumber:phone];
            [[SQFriendsOnSquawk shared] gotPhonesOfFriendsOnSquawk:@[phone]];
        }
        completionHandler(UIBackgroundFetchResultNewData);
    } else if ([userInfo[@"type"] isEqualToString:@"checkmark"]) {
        [self toast:[userInfo[@"aps"] objectForKey:@"alert"]];
        completionHandler(UIBackgroundFetchResultNoData);
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}
#pragma mark UI
-(void)toast:(NSString*)toast {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        // TODO: immediate local notification
        UILocalNotification* notif = [UILocalNotification new];
        notif.alertBody = toast;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    } else {
        [WSToastNotificationView showToastMessage:toast inView:self.window.rootViewController.view];
    }
}
-(UIViewController*)frontmostViewController {
    UIViewController* vc = self.window.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}
#pragma mark Analytics
-(void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)val {
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:val] build]];
}
#pragma mark Background downloads
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    [[SQBackgroundTaskManager shared] launchedWithCompletionHandler:completionHandler];
}
#pragma mark Global properties
-(void)setupGlobalProperties {
    self.globalProperties = [WSPersistentDictionary shared][@"SQGlobalProperties"];
    RACSignal* appOpened = [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil];
    [appOpened subscribeNext:^(id x) {
        NSTimeInterval dt = [NSDate timeIntervalSinceReferenceDate] - [[NSUserDefaults standardUserDefaults] doubleForKey:@"LastGlobalPropertiesRefresh"];
        if (dt > GLOBAL_PROPERTIES_REFRESH_INTERVAL) {
            NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/globals.json", API_ROOT]];
            [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (data && !error) {
                    NSDictionary* props = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    [WSPersistentDictionary shared][@"SQGlobalProperties"] = props;
                    self.globalProperties = props;
                    [[NSUserDefaults standardUserDefaults] setDouble:[NSDate timeIntervalSinceReferenceDate] forKey:@"LastGlobalPropertiesRefresh"];
                }
            }] resume];
        }
    }];
    
    [RACObserve(self, globalProperties) subscribeNext:^(NSDictionary* props) {
        double version = BUILD_NUM;
        for (NSDictionary* message in props[@"messages"]) {
            BOOL shouldShow = YES;
            if (message[@"max_version"])
                shouldShow = shouldShow && version <= [message[@"max_version"] doubleValue];
            if (message[@"min_version"])
                shouldShow = shouldShow && version >= [message[@"min_version"] doubleValue];
            if (message[@"presentation_key"])
                shouldShow = shouldShow && ![[NSUserDefaults standardUserDefaults] boolForKey:message[@"presentation_key"]];
            if (shouldShow) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIViewController* frontmost = [self frontmostViewController];
                    if ([frontmost isKindOfClass:[UINavigationController class]] && [[(UINavigationController*)frontmost viewControllers].firstObject isKindOfClass:[SQMessageViewController class]]) return;
                    SQMessageViewController* messageVC = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"MessageViewController"];
                    messageVC.message = message;
                    [frontmost presentViewController:[[UINavigationController alloc] initWithRootViewController:messageVC] animated:YES completion:nil];
                });
                
                break;
            }
        }
    }];
}
#pragma mark URL scheme
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.scheme.lowercaseString isEqualToString:@"squawk"]) {
        NSString* command = url.host;
        if ([command isEqualToString:@"add"]) {
            NSDictionary* query = url.queryDictionary;
            if (query[@"phone"]) {
                [SQThreadMakerViewController prepopulationDict][@"phone"] = query[@"phone"];
                if (query[@"name"]) {
                    [SQThreadMakerViewController prepopulationDict][@"name"] = query[@"name"];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:SQPromptAddFriend object:nil userInfo:nil];
                return YES;
            }
        }
    }
    return NO;
}

@end
