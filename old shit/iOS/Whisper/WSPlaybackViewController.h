//
//  WSPlaybackViewController.h
//  Whisper
//
//  Created by Nate Parrott on 1/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface WSPlaybackView : UIView <AVAudioPlayerDelegate> {
    AVAudioPlayer* _player;
    IBOutlet UIPageControl* _pageControl;
    IBOutlet UIProgressView* _loadProgress;
}

@property(strong,nonatomic)NSArray* recordings;
@property(strong,nonatomic)PFObject* playing;
-(void)startPlayback;
-(IBAction)prev:(id)sender;
-(IBAction)next:(id)sender;

@end
