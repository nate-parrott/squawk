//
//  SQAppDelegate.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>

#define API_ROOT @"http://squawkapp.herokuapp.com"
//#define API_ROOT @"http://localhost:5000"
#define VERIFICATION_NUMBER @"646-576-7688"
#define MAX_RECORDING_DURATION (7 * 60 * 60)
#define GLOBAL_PROPERTIES_REFRESH_INTERVAL 4 * 60 * 60 // 4 hrs

// this is just NSLog, but doesn't print on release builds.
#define DBLog(...) do {} while (0)
#ifdef DEBUG
#undef DBLog
#define DBLog(...) NSLog(__VA_ARGS__)
#endif

#define AppDelegate ((SQAppDelegate*)[[UIApplication sharedApplication] delegate])

//#define TAKING_DEFAULT_IMAGE

//#define PRETTIFY

#define BUILD_NUM ([[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] doubleValue])

void JSLog(id jsonObj);

NSString* SQErrorDomain;
NSString* SQDidOpenMessageNotification;
NSString* SQPromptAddFriend;

@interface SQAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)setupPushNotifications;
@property BOOL pushNotificationsEnabled;

@property BOOL hasRecordPermission;
@property BOOL tryToRecord;

-(void)toast:(NSString*)toast;

-(void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)val;

@property(strong)NSDictionary* globalProperties;

@end
