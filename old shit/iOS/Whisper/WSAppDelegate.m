//
//  WSAppDelegate.m
//  Whisper
//
//  Created by Nate Parrott on 1/22/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "WSAppDelegate.h"
#import "WSMainViewController.h"
#import "WSWelcomeViewController.h"
#import "WSToastNotificationView.h"
#import "NSString+RandomString.h"
#import "NSDate+MMAdditions.h"
#import "WSFriendsOnSquawk.h"
#import "NSURLRequest+PerformWithBlockCallback.h"
#import "WSLockoutViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import <Crashlytics/Crashlytics.h>
#import "WSPersistentDictionary.h"
#import "WSContactBoost.h"
#import <Helpshift.h>

#define AUTOPLAY_ENABLED NO

NSString* WSErrorDomain = @"WSErrorDomain";

NSString *WSAuthorizationUnknown = @"unknown";
NSString *WSAuthorizationDenied = @"denied";
NSString *WSAuthorizationGranted = @"granted";

NSString *WSMultisquawkEnabled = @"WSMultisquawkEnabled";
NSString *WSRaiseToSquawkEnabled = @"WSRaiseToSquawkEnabled";

void JSLog(id jsonObj) {
    NSString* s =  [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObj options:0 error:0] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", s);
}

@implementation WSAppDelegate

#pragma mark Setup methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [PFCloud callFunction:@"joined" withParameters:@{@"nickname": @"nate"}];
        NSLog(@"joined");
    });*/
    
    self.appState = [RACReplaySubject replaySubjectWithCapacity:1];
    [self.appState sendNext:@(UIApplicationStateActive)];
    
    [Helpshift installForApiKey:@"51e4c98d95cfbf0b3e22b90537203f26" domainName:@"squawk.helpshift.com" appID:@"squawk_platform_20140227180649929-134e795f46f5dc2"];
    
    [Crashlytics startWithAPIKey:@"c00a274f2c47ad5ee89b17ccb2fdb86e8d1fece8"];
    
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelWarning];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-47910043-1"];
    
    [self setupDefaults];
    
    [self applyTheme];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [[NSUserDefaults standardUserDefaults] setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"LastLaunchedVersion"];
    
    self.appOpened = [RACSubject subject];
    self.messageNotifications = [RACSubject subject];
    self.pushAuthorization = [RACReplaySubject replaySubjectWithCapacity:1];
    [self.pushAuthorization sendNext:WSAuthorizationUnknown];
    
    [self setupGlobalProperties];
    
    self.promptSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"blip1" withExtension:@"wav"] error:nil];
    self.longPromptSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"longblips2" withExtension:@"wav"] error:nil];
    self.whooshPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"short_whoosh" withExtension:@"wav"] error:nil];
    self.cancelPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"electric_deny2" withExtension:@"wav"] error:nil];
    self.cancelPlayer.volume = 0.4;
    
    application.applicationSupportsShakeToEdit = NO;
            
    [Parse setApplicationId:@"lEf1qOOpwSfPKKDcOTPuFOxfZJa5ArkaCDRZqPpu"
                  clientKey:@"IyoFHiUjlOuHvhHp3UxJKSpsBhfg8vpEExENQg3Q"];
    
    self.currentUser = [PFUser currentUser];
    
    RACSignal* currentUser = [RACObserve(self, currentUser) distinctUntilChanged];
    RACSignal* lockedOut = [self.globalProperties map:^id(NSDictionary* props) {
        return @(!!props[@"lockoutMessage1"]);
    }];
    RAC(self.window, rootViewController) = [[[RACSignal combineLatest:@[currentUser, lockedOut]] distinctUntilChanged] reduceEach:^id(PFUser* user, NSNumber* isLockedOut) {
        if (isLockedOut.boolValue) {
            return [[WSLockoutViewController alloc] initWithNibName:@"WSLockoutViewController" bundle:nil];
        }
        if (user) {
            return [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"LoggedIn"];
        } else {
            return [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"NotLoggedIn"];
        }
    }];
    
    self.didLaunchWithNotification = [RACSubject subject];
    
    [self fadeoutSplashScreen];
    
    [self.window makeKeyAndVisible];
    
    [self.appOpened sendNext:nil];
    
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    
    return YES;
}

-(void)setupDefaults {
    for (NSString* key in @[WSRaiseToSquawkEnabled, WSMultisquawkEnabled]) {
        if (![[NSUserDefaults standardUserDefaults] valueForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:key];
        }
    }
}

-(void)setupGlobalProperties {
    self.globalProperties = [RACReplaySubject replaySubjectWithCapacity:1];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"GlobalPropertiesData"]) {
        [self.globalProperties sendNext:[NSJSONSerialization JSONObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"GlobalPropertiesData"] options:0 error:nil]];
    } else {
        [self.globalProperties sendNext:nil];
    }
    [self.appOpened subscribeNext:^(id x) {
        NSTimeInterval dt = [NSDate timeIntervalSinceReferenceDate] - [[NSUserDefaults standardUserDefaults] doubleForKey:@"LastGlobalPropertiesRefresh"];
        if (dt > GLOBAL_PROPERTIES_REFRESH_INTERVAL) {
            [[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.squawkwith.us/global.json"]] performRequestWithCallback:^(NSData *data, NSError *error) {
                if (data && !error) {
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"GlobalPropertiesData"];
                    NSDictionary* props = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    [self.globalProperties sendNext:props];
                    [[NSUserDefaults standardUserDefaults] setDouble:[NSDate timeIntervalSinceReferenceDate] forKey:@"LastGlobalPropertiesRefresh"];
                }
            }];
        }
    }];

}

-(void)applyTheme {
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.961 green:0.827 blue:0.396 alpha:1]];
    //[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:1.000 green:0.806 blue:0.000 alpha:1.000]];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Avenir-Heavy" size:16]];
}

/*-(void)UPLOAD_TEAM_SQUAWK_WELCOME {
    // turn off User object protection on the dashboard before running this
    // DO NOT INCLUDE IN PRODUCTION
    PFUser* teamSquawk = [PFUser user];
    [teamSquawk setUsername:@"15555551234"];
    [teamSquawk setPassword:@"e82q2U48PM528JaGXaK8"];
    [teamSquawk signUp];
    [teamSquawk setValue:@"Team Squawk" forKey:@"nickname"];
    [teamSquawk setValue:@YES forKey:@"joined"];
    [teamSquawk save];
    
    PFFile* f = [PFFile fileWithName:@"Welcome.m4a" contentsAtPath:@"/Users/nateparrott/Desktop/welcome-preliminary.m4a"];
    [f save];
    PFObject* msg = [PFObject objectWithClassName:@"Message"];
    [msg setValue:@"WELCOME" forKey:@"id2"];
    [msg setValue:teamSquawk forKey:@"sender"];
    [msg setValue:teamSquawk forKey:@"recipient"];
    [msg setValue:f forKey:@"file"];
    PFACL* acl = [PFACL ACL];
    [acl setPublicReadAccess:NO];
    [acl setPublicWriteAccess:NO];
    [msg setACL:acl];
    [msg save];
    NSLog(@"done");
}*/

-(void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)val {
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:val] build]];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url pathExtension].lowercaseString isEqual:@"m4a"]) {
        long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil][NSFileSize] longLongValue];
        if (fileSize==0) {
            [[[UIAlertView alloc] initWithTitle:@"Error Opening File" message:@"Another app gave Squawk an empty file to open." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else if (fileSize > 1024 * 1024) {
            [[[UIAlertView alloc] initWithTitle:@"File Too Large" message:@"You can't Squawk files larger than 1 MB." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            self.queuedAudioFileURL = url;
        }
        return YES;
    }
    return NO;
}

-(void)fadeoutSplashScreen {
    UIImage* defaultImage = [UIScreen mainScreen].bounds.size.height==480? [UIImage imageNamed:@"Default-480"] : [UIImage imageNamed:@"Default-568"];
    UIView* root = self.window.rootViewController.view;
    
    UIView* container = [UIView new];
    [root addSubview:container];
    container.frame = root.bounds;
    
    UIImageView* splash = [[UIImageView alloc] initWithImage:defaultImage];
    [container addSubview:splash];
    splash.frame = root.bounds;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15 delay:0.0 options:0 animations:^{
            splash.alpha = 0;
        } completion:^(BOOL finished) {
            [container removeFromSuperview];
        }];
    });
}
-(void)logOut {
    if (self.currentUser) {
        [[PFUser currentUser] removeObject:[PFInstallation currentInstallation] forKey:@"installations"];
        [[PFUser currentUser] saveInBackground];
        [PFUser logOut];
        self.currentUser = nil;
        [[WSPersistentDictionary shared] reset];
    }
}
#pragma mark Notifications
-(void)registerForPushNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
}
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    [self.pushAuthorization sendNext:WSAuthorizationGranted];
}
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.pushAuthorization sendNext:WSAuthorizationDenied];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo  {
    if ([userInfo[@"type"] isEqualToString:@"confirmation"]) {
        NSString* alert = [userInfo[@"aps"] valueForKeyPath:@"alert"];
        [WSToastNotificationView showToastMessage:alert inView:self.window.rootViewController.view];
    } else if ([userInfo[@"type"] isEqualToString:@"message"]) {
        NSString* receivedMessageID = userInfo[@"id2"];
        if (application.applicationState!=UIApplicationStateActive) { // only trigger autoplay if this notification was tapped to launch the app
            [self.didLaunchWithNotification sendNext:nil];
            if (receivedMessageID && AUTOPLAY_ENABLED) {
                self.autoplayMessageID = receivedMessageID;
                self.timeOfAutoplayInvocation = [NSDate date];
            }
        }
        [self.messageNotifications sendNext:userInfo];
    } else if ([userInfo[@"type"] isEqualToString:@"friendJoined"]) {
        [[WSFriendsOnSquawk manager] addKnownPhoneNumber:userInfo[@"phone"]];
        [WSContactBoost boostPhoneNumber:userInfo[@"phone"]];
    }
}

/*-(void)fetchMessageInBackgroundWithID:(NSString*)messageID completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    //NSLog(@"waiting for message %@", messageID);
    // receipt of the push notification will trigger a reload, so just wait until the new data becomes available
    // it's okay to get a stale (replayed) squawk list from the lastFetchedRecentSquawkOrError ReplaySubject, but we don't want to report failure if we get a stale error
    __block BOOL staleData = YES;
    RACSignal* fetchResult = [[self.lastFetchedRecentSquawkOrError map:^id(id value) {
        if ([value isKindOfClass:[NSError class]] && staleData) {
            staleData = NO;
            return nil;
        }
        staleData = NO;
        if ([value isKindOfClass:[NSArray class]]) {
            BOOL success = [[value rac_sequence] any:^BOOL(id value) {
                return [[value valueForKey:@"id2"] isEqualToString:messageID];
            }];
            if (success) {
                return @(UIBackgroundFetchResultNewData);
            } else {
                return nil;
            }
        } else {
            return @(UIBackgroundFetchResultFailed);
        }
    }] filter:^BOOL(id value) {
        return !!value;
    }];
    [[fetchResult take:1] subscribeNext:^(id x) {
        //NSLog(@"Result for message %@: %i", messageID, [x integerValue]);
        completionHandler([x integerValue]);
    }];
}
 
 -(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    if ([userInfo[@"type"] isEqualToString:@"confirmation"]) {
        NSString* alert = [userInfo[@"aps"] valueForKeyPath:@"alert"];
        [WSToastNotificationView showToastMessage:alert inView:self.window.rootViewController.view];
    } else if ([userInfo[@"type"] isEqualToString:@"message"]) {
        NSString* receivedMessageID = userInfo[@"id2"];
        if (application.applicationState!=UIApplicationStateActive) { // only trigger autoplay if this notification was tapped to launch the app
            [self.didLaunchWithNotification sendNext:nil];
            if (receivedMessageID && AUTOPLAY_ENABLED) {
                self.autoplayMessageID = receivedMessageID;
                self.timeOfAutoplayInvocation = [NSDate date];
            }
        }
        [self fetchMessageInBackgroundWithID:receivedMessageID completionHandler:completionHandler];
        completionHandler = nil;
        [self.messageNotifications sendNext:userInfo];
    } else if ([userInfo[@"type"] isEqualToString:@"friendJoined"]) {
        [[WSFriendsOnSquawk manager] addKnownPhoneNumber:userInfo[@"phone"]];
        [WSContactBoost boostPhoneNumber:userInfo[@"phone"]];
    }
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}
 */
#pragma mark App state
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.appState sendNext:@(UIApplicationStateInactive)];
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.appState sendNext:@(UIApplicationStateActive)];
    [self.appOpened sendNext:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.appState sendNext:@(UIApplicationStateActive)];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark User invitation
-(void)promptUserToJoin:(NSString*)phoneNumber {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Someone's missing out!", @"Title for alert when you squawk someone who hasn't signed up") message:[NSString stringWithFormat:NSLocalizedString(@"%@ isn't on Squawk. To receive your message, they'll have to get the app.", @""), phoneNumber] delegate:self cancelButtonTitle:NSLocalizedString(@"Okay", @"") otherButtonTitles:NSLocalizedString(@"Text them an invite", @""), nil];
    self.intendedUserForInvitation = phoneNumber;
    [av show];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    BOOL shouldInvite = buttonIndex != alertView.cancelButtonIndex;
    if (shouldInvite) {
        
        if(![MFMessageComposeViewController canSendText]) {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Looks like your device doesn't support SMS :(", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", @"") otherButtonTitles:nil];
            [warningAlert show];
            return;
        }
        
        NSArray *recipents = [NSArray arrayWithObject:self.intendedUserForInvitation];
        NSString *message = NSLocalizedString(@"You've got a voice message on Squawk! Download the app to check it out. http://squawkwith.us/a.html", @"");
        
        _messageSender = [[MFMessageComposeViewController alloc] init];
        _messageSender.messageComposeDelegate = self;
        [_messageSender setRecipients:recipents];
        [_messageSender setBody:message];
        
        // Present message view controller on screen
        [self.window.rootViewController presentViewController:_messageSender animated:YES completion:nil];
        
    }
    [AppDelegate trackEventWithCategory:@"ui_action" action:@"prompt_to_invite" label:nil value:@(shouldInvite)];
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark Background upload
-(void)addOngoingTaskWithID:(NSString*)taskID {
    if (!_ongoingTasks) {
        _ongoingTasks = [NSMutableSet new];
    }
    [_ongoingTasks addObject:taskID];
}
-(void)finishedOngoingTaskWithID:(NSString*)taskId {
    [_ongoingTasks removeObject:taskId];
    if ([_ongoingTasks count]==0 && _bgTask) {
        UIBackgroundTaskIdentifier bgTask = _bgTask;
        _bgTask = 0;
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }
}
-(void)applicationDidEnterBackground:(UIApplication *)application {
    [self.appState sendNext:@(UIApplicationStateBackground)];
    if (_ongoingTasks.count) {
        _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [_ongoingTasks removeAllObjects];
        }];
    }
}

@end
