//
//  WSPlaybackViewController.m
//  Whisper
//
//  Created by Nate Parrott on 1/24/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSPlaybackViewController.h"
#import "WSMainViewController.h"

@interface WSPlaybackView ()

@end

@implementation WSPlaybackView

-(void)setPlaying:(PFObject *)playing {
    _playing = playing;
    _player.delegate = nil;
    [_player stop];
    _player = nil;
    PFFile* file = [playing valueForKey:@"file"];
    _loadProgress.hidden = NO;
    _pageControl.numberOfPages = _recordings.count;
    _pageControl.currentPage = [_recordings indexOfObject:playing];
    self.userInteractionEnabled = NO;
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        _loadProgress.hidden = YES;
        self.userInteractionEnabled = YES;
        _player = [[AVAudioPlayer alloc] initWithData:data error:nil];
        _player.delegate = self;
        [_player prepareToPlay];
        [_player play];
        [playing setValue:@YES forKey:@"listened"];
        [playing saveInBackground];
    } progressBlock:^(int percentDone) {
        _loadProgress.progress = percentDone/100.0;
    }];
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self next:nil];
}
-(void)startPlayback {
    for (PFObject* rec in self.recordings) {
        if ([[rec valueForKey:@"listened"] boolValue]==NO) {
            [self setPlaying:rec];
            return;
        }
    }
    [self setPlaying:self.recordings.lastObject];
}
-(IBAction)prev:(id)sender {
    int index = [self.recordings indexOfObject:self.playing];
    if (index > 0) {
        [self setPlaying:self.recordings[index-1]];
    }
}
-(IBAction)next:(id)sender {
    int index = [self.recordings indexOfObject:self.playing];
    if (index+1 < self.recordings.count) {
        [self setPlaying:self.recordings[index+1]];
    } else {
        [self removeFromSuperview];
    }
}
-(void)removeFromSuperview {
    [_player stop];
    _player = nil;
    [super removeFromSuperview];
}
-(void)setRecordings:(NSArray *)recordings {
    _recordings = [recordings sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 valueForKey:@"createdAt"] compare:[obj2 valueForKey:@"createdAt"]];
    }];
}

@end
