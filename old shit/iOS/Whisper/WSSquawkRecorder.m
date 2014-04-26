//
//  WSAudio.m
//  Squawk
//
//  Created by Nate Parrott on 2/1/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSSquawkRecorder.h"
#import "WSAppDelegate.h"
#import "WSToastNotificationView.h"
#import "WSAppDelegate+GlobalUIExtensions.h"
#import "WSMultisquawkCellTableViewCell.h"

@implementation WSSquawkRecorder

+(NSMutableSet*)currentlyRunningRecorders {
    static NSMutableSet* recs = nil;
    if (!recs) {
        recs = [NSMutableSet new];
    }
    return recs;
}

+(void)getInitializedAudioRecorder:(AVAudioRecorder**)recorder url:(NSURL**)url {
    static int i = 0;
    
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"output-%.m4a", (i++)%5]];
    *url = [NSURL fileURLWithPath:path];
    
    NSError* err = nil;
    NSDictionary* settings = nil;
    //settings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVNumberOfChannelsKey: @1, AVEncoderAudioQualityKey: @(AVAudioQualityLow), AVSampleRateKey: @22050};
    settings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVNumberOfChannelsKey: @1, AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_VariableConstrained, AVEncoderAudioQualityForVBRKey: @(AVAudioQualityLow), AVSampleRateKey: @22050};
    //settings = @{AVFormatIDKey: @(kAudioFormatiLBC)};
    *recorder = [[AVAudioRecorder alloc] initWithURL:*url settings:settings error:&err];
    if (err || ![*recorder prepareToRecord]) {
        *recorder = nil;
    }
}
+(NSTimeInterval)maxDuration {
    return 7 * 60;
}
+(NSTimeInterval)postStopRecordingDelay {
    return 0.2;
}
-(BOOL)startRecording {
    [[WSSquawkRecorder currentlyRunningRecorders] addObject:self];
    
    AVAudioRecorder* recorder;
    NSURL* url;
    [WSSquawkRecorder getInitializedAudioRecorder:&recorder url:&url];
    _recorder = recorder;
    _url = url;
    if (!_recorder) {
        [AppDelegate trackEventWithCategory:@"error" action:@"record_error" label:@"failed to initialize AVAudioRecorder" value:nil];
        return NO;
    }
    recorder.delegate = self;
    
    _promptSoundPlayer = self.isEarDriven? AppDelegate.longPromptSoundPlayer : AppDelegate.promptSoundPlayer;
    [_promptSoundPlayer setCurrentTime:0];
    [_promptSoundPlayer play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_promptSoundPlayer.duration + 0.05) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_cancelled) {
            _recordingStartDate = [NSDate timeIntervalSinceReferenceDate];
            if (![recorder recordForDuration:[WSSquawkRecorder maxDuration]]) {
                [AppDelegate trackEventWithCategory:@"error" action:@"record_error" label:@"-recordForDuration: failed" value:nil];
            }
        }
    });
    return YES;
}
-(void)stopRecording {
    [_promptSoundPlayer stop];
    
    if ([_recorder isRecording]) {
        [_recorder performSelector:@selector(stop) withObject:nil afterDelay:[WSSquawkRecorder postStopRecordingDelay]];
    } else {
        // it's okay—the app won't send because the message was too short
        [self audioRecorderDidFinishRecording:_recorder successfully:YES];
    }
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    void (^cancel)() = ^{
        [[WSSquawkRecorder currentlyRunningRecorders] removeObject:self];
        _recorder.delegate = nil;
        [_recorder stop];
        _recorder = nil;
    };
    
    if (self.onFinish) self.onFinish(nil);
    NSTimeInterval timeout = self.isEarDriven? 1.5 : 0.4;
    if (!_recordingStartDate || [NSDate timeIntervalSinceReferenceDate] - _recordingStartDate < timeout-[WSSquawkRecorder postStopRecordingDelay]) {
        if (!self.isEarDriven) {
            [AppDelegate toast:NSLocalizedString(@"Hold the button to Squawk.", @"")];
        }
        /*if (self.isEarDriven) {
            [AppDelegate.cancelPlayer setCurrentTime:0];
            [AppDelegate.cancelPlayer play];
        }*/
        cancel();
        return;
    }
    if (_cancelled || !flag) {
        cancel();
        return;
    }
    [AppDelegate toast:@"Sending Squawk..."];
    [AppDelegate.whooshPlayer setCurrentTime:0];
    [AppDelegate.whooshPlayer play];
    
    //fields:
    //   senderPhoneNumber        string
    //   recipientPhoneNumber     string
    //   file                     file
    //   duration                 number
    //   listened                 BOOL
    
    [self sendAudioFileAtURL:_url completed:^id(id x) {
        return nil;
    }];
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    [AppDelegate trackEventWithCategory:@"error" action:@"encode_error" label:error.localizedDescription value:nil];
}
-(void)cancelRecording {
    // stop prompt sounds:
    [AppDelegate.promptSoundPlayer stop];
    [AppDelegate.longPromptSoundPlayer stop];
    
    _cancelled = YES;
    if ([_recorder isRecording])
        [_recorder stop];
    else
        [self audioRecorderDidFinishRecording:_recorder successfully:NO];
}

-(void)sendAudioFileAtURL:(NSURL*)url completed:(WSGenericCallback)callback {
    
    [AppDelegate trackEventWithCategory:@"ui_action" action:@"sent_squawk" label:nil value:@(self.recipientPhoneNumbers.count)];
    [[WSSquawkRecorder currentlyRunningRecorders] addObject:self];
    
    static int lastUploadID = 0;
    NSString* taskID = [NSString stringWithFormat:@"MessageUpload-%i", lastUploadID++];
    [AppDelegate addOngoingTaskWithID:taskID];
    
    __block BOOL isThreaded = NO;
    
    void(^done)(BOOL) = ^(BOOL success) {
        if (callback) callback(nil);
        [[WSSquawkRecorder currentlyRunningRecorders] removeObject:self];
        [AppDelegate finishedOngoingTaskWithID:taskID];
        if (success && isThreaded) {
            [[AppDelegate messageNotifications] sendNext:nil];
        }
    };
    
    int size = [[[NSFileManager defaultManager] attributesOfItemAtPath:_url.path error:nil][NSFileSize] integerValue];
    double duration = [NSDate timeIntervalSinceReferenceDate]-_recordingStartDate;
    NSLog(@"%f seconds; %i bytes; %f bytes/sec", duration, size, size/duration);
    
     
    PFFile *file = [PFFile fileWithName:@"squawk.ilbc" contentsAtPath:_url.path];
    
    RACSignal* fileUpload = [[[RACSignal empty] startWith:nil] flattenMap:^RACStream *(id value) {
        RACSubject* subj = [RACSubject subject];
        [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            if (error) {
                [subj sendError:error];
            } else {
                [subj sendNext:nil];
                [subj sendCompleted];
            }
        }];
        return subj;
    }];
    RACSignal* recipients = [[[[[RACSignal empty] startWith:nil] flattenMap:^RACStream *(id value) {
        RACSubject* subj = [RACSubject subject];
        /* if there's only 1 recipient phone #, fetch their user with getUserByPhone, which will create a user and queue their message if they aren't signed up. if it's a multisquawk, it's too much work to do for everyone, so call getUsersByPhone, which will return all ALREADY-REGISTERED users matching the given #s */
        if (self.recipientPhoneNumbers.count==1) {
            [PFCloud callFunctionInBackground:@"getUserByPhone" withParameters:@{@"phoneNumber": self.recipientPhoneNumbers.firstObject} block:^(id user, NSError *error) {
                if (error) {
                    [subj sendError:error];
                } else {
                    [subj sendNext:@[user]];
                    [subj sendCompleted];
                }
            }];
        } else if (self.recipientPhoneNumbers.count > 1) {
            [PFCloud callFunctionInBackground:@"getUsersByPhone" withParameters:@{@"phoneNumbers": self.recipientPhoneNumbers} block:^(id users, NSError *error) {
                if (error) {
                    [subj sendError:error];
                } else {
                    [subj sendNext:users];
                    [subj sendCompleted];
                }
            }];
        }
        return subj;
    }] publish] autoconnect];
    // if it's a multisquawk, add ourselves to the thread:
    recipients = [recipients map:^id(NSArray* recipients) {
        BOOL alreadyContainsSelf = NO;
        for (PFUser* recip in recipients) {
            if ([recip.objectId isEqualToString:[PFUser currentUser].objectId]) alreadyContainsSelf = YES;
        }
        if (recipients.count > 1 && !alreadyContainsSelf) {
            recipients = [recipients arrayByAddingObject:[PFUser currentUser]];
        }
        return recipients;
    }];
    
    __block NSArray* recipientUsers = nil;
    [recipients subscribeNext:^(id x) {
        recipientUsers = x;
    }];
    [[[[[RACSignal combineLatest:@[fileUpload, recipients]] take:1] flattenMap:^RACStream *(RACTuple* value) {
        return [value.second rac_sequence].signal;
    }] flattenMap:^RACStream *(PFUser* recipientUser) {
        RACSubject* subj = [RACSubject subject];
        
        PFUser* senderUser = [PFUser currentUser];
        NSNumber* listened = @NO;
        if ([recipientUser.objectId isEqualToString:[PFUser currentUser].objectId]) listened = @YES;
        NSDictionary* data = @{@"sender": senderUser, @"recipient": recipientUser, @"file": file, @"listened": listened};
        PFObject* message = [PFObject objectWithClassName:@"Message" dictionary:data];
        PFACL* acl = [PFACL ACL];
        [acl setPublicReadAccess:NO];
        [acl setPublicWriteAccess:NO];
        [acl setWriteAccess:YES forUser:senderUser];
        [acl setReadAccess:YES forUser:senderUser];
        [acl setWriteAccess:YES forUser:recipientUser];
        [acl setReadAccess:YES forUser:recipientUser];
        [message setACL:acl];
        
        if (recipientUsers.count > 1) {
            // it's a multisquawk thread:
            isThreaded = YES;
            for (PFUser* recipient in recipientUsers) {
                [message addUniqueObject:recipient forKey:@"threadMembers"];
            }
        }
        
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [WSToastNotificationView showToastMessage:NSLocalizedString(@"Squawk failed!", @"") inView:AppDelegate.window.rootViewController.view];
            }
            if (error) {
                [subj sendError:error];
            } else {
                [subj sendCompleted];
            }
        }];
        return subj;
    }] subscribeError:^(NSError *error) {
        [AppDelegate toast:@"Squawk failed!"];
        [AppDelegate trackEventWithCategory:@"error" action:@"squawk_failed" label:error.description value:nil];
        if ([UIApplication sharedApplication].applicationState==UIApplicationStateBackground) {
            UILocalNotification* notif = [[UILocalNotification alloc] init];
            notif.alertBody = @"Squawk failed :-(";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
        }
        done(NO);
    } completed:^{
        done(YES);
    }];
    
    [[recipients take:1] subscribeNext:^(NSArray* recipients) {
        if (recipients.count==1) {
            PFUser* recipientUser = recipients.firstObject;
            BOOL userHasInstallation = [recipientUser valueForKey:@"installation"] || [[recipientUser valueForKey:@"installations"] count] > 0;
            if (!userHasInstallation && self.recipientPhoneNumbers.count==1) {
                [AppDelegate promptUserToJoin:[recipientUser valueForKey:@"username"]];
            }
        }
    }];
}

@end
