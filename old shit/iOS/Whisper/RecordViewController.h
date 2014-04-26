//
//  RecordViewController.h
//  Whisper
//
//  Created by Justin Brower on 1/24/14.
//  Copyright (c) 2014 Justin Brower. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define RECORDING_LENGTH 2*60
@class RecordViewController;
@protocol RecordViewControllerDelegate

@optional

//recording
- (void)recordViewDidFinishRecording:(RecordViewController *)recordView;
- (void)recordViewDidStartRecording:(RecordViewController *)recordView;
- (void)recordViewDidFailRecord:(RecordViewController *)recordView withError:(NSError *)error;

//uploading
- (void)recordViewDidStartUpload:(RecordViewController *)recordView;
- (void)recordViewDidCompleteUpload:(RecordViewController *)recordView;
- (void)recordViewDidFailUpload:(RecordViewController *)recordView withError:(NSError *)error;

@end


@interface RecordViewController : UIViewController <AVAudioRecorderDelegate> {
    
}

@property (strong) id <RecordViewControllerDelegate>delegate;
@property (strong) AVAudioRecorder *audioRecorder;

-(IBAction)startRecording:(id)sender;




/*   Creates a new Message object with the given parameters (sender, recipient, duration)
 *   and a corresponding File object to hold the post.
 */
- (void)uploadOutputToServerWithRecipient:(NSString *)recipient duration:(float)duration;

-(IBAction)stopRecording:(id)sender;

@end


