//
//  SQAudioAction.h
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SQStatusViewCard;

@class SQAudioAction;
@protocol SQAudioActionDelegate <NSObject>

-(void)audioActionFinished:(SQAudioAction*)action;
-(void)audioAction:(SQAudioAction*)action failedWithError:(NSError*)error;

@end

NSString* SQAudioActionStatusChanged; // called by subclasses for various things, like a change in a loading property

@interface SQAudioAction : NSObject

-(void)start;
-(void)stop;
-(void)abort;
@property(weak)id<SQAudioActionDelegate> delegate;
@property BOOL started, stopped, cancelled;

-(SQStatusViewCard*)statusView;

-(void)refreshDisplay;

@end
