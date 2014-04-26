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

@property BOOL allowsPlayback;
@property BOOL showInviteControl;
@property BOOL showCheckmarkControl;

@property BOOL showingPlayback;
-(void)showPlayback:(BOOL)showing;

@property(strong)NSAttributedString *playbackMessage, *recordMessage;

@property(weak)IBOutlet id<SQSquawkBarDelegate> delegate;

@end
