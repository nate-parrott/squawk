//
//  SQSquawkBar.h
//  Squawk2
//
//  Created by Nate Parrott on 4/23/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQSquawkBar;
@protocol SQSquawkBarDelegate <NSObject>

-(void)playbackOrRecordHeldDown:(SQSquawkBar*)squawkBar;
-(void)playbackOrRecordPickedUp:(SQSquawkBar*)squawkBar;
-(void)playbackOrRecordCancelled:(SQSquawkBar*)squawkBar;
-(void)sendCheckmark:(SQSquawkBar*)squawkBar;
-(void)inviteFriend:(SQSquawkBar*)squawkBar;

@end


@interface SQSquawkBar : UIView

@property(readonly) BOOL allowsPlayback;
@property(readonly) BOOL showInviteControl;
@property(readonly) BOOL showCheckmarkControl;

@property BOOL showingPlayback;
-(void)showPlayback:(BOOL)showing;

@property(strong,readonly)NSAttributedString *playbackMessage, *recordMessage;

@property(weak)IBOutlet id<SQSquawkBarDelegate> delegate;

-(void)setShowsInviteLabel:(BOOL)inviteLabel allowsPlackback:(BOOL)allowsPlayback showsCheckmark:(BOOL)showsCheckmark playbackLabel:(NSAttributedString*)playbackString recordLabel:(NSAttributedString*)recordString;


@end
