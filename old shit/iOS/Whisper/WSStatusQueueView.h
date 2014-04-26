//
//  WSStatusQueueView.h
//  Whisper
//
//  Created by Nate Parrott on 1/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSStatusQueueView : UIView

-(void)addStatus:(NSString*)status withLoader:(BOOL)loader;

@end
