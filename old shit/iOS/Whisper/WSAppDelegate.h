//
//  WSAppDelegate.h
//  Whisper
//
//  Created by Nate Parrott on 1/22/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <ReactiveCocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#define AppDelegate ((WSAppDelegate*)[[UIApplication sharedApplication] delegate])

#define GLOBAL_PROPERTIES_REFRESH_INTERVAL 4 * 60 * 60 // 4 hrs
#define WSFriendsOnSquawkRefreshInterval 60 * 60 * 24 // 1 day

//#define TAKING_DEFAULT_IMAGE

void JSLog(id jsonObj);

typedef id (^WSGenericCallback)(id x);
typedef void (^WSEmptyCallback)();

NSString *WSAuthorizationUnknown, *WSAuthorizationDenied, *WSAuthorizationGranted;

NSString* WSErrorDomain;

NSString *WSMultisquawkEnabled, *WSRaiseToSquawkEnabled;

@interface WSAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, MFMessageComposeViewControllerDelegate> {
    MFMessageComposeViewController* _messageSender;
    
    NSMutableSet* _ongoingTasks;
    UIBackgroundTaskIdentifier _bgTask;
}

@property(strong)RACSubject* appOpened;
@property(strong)RACSubject* messageNotifications;
@property(strong)RACSubject* pushAuthorization;
@property(strong)PFUser* currentUser;
-(void)logOut;
@property(strong)RACSubject* didLaunchWithNotification;
@property(strong)RACSubject* appState;

@property(strong)RACReplaySubject* globalProperties;

@property(strong)NSURL* queuedAudioFileURL;

-(void)registerForPushNotifications;

@property (strong) NSString *intendedUserForInvitation;
@property (strong, nonatomic) UIWindow *window;

-(void)promptUserToJoin:(NSString*)phoneNumber;

@property(strong)AVAudioPlayer *promptSoundPlayer, *longPromptSoundPlayer, *whooshPlayer, *cancelPlayer;

-(void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)val;

@property(strong)NSString* autoplayMessageID;
@property(strong)NSDate* timeOfAutoplayInvocation;

-(void)addOngoingTaskWithID:(NSString*)taskID;
-(void)finishedOngoingTaskWithID:(NSString*)taskId;

@end
