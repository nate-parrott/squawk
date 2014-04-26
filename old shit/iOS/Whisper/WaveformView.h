//
//  WaveformView.h
//  Whisper
//
//  Created by Justin Brower on 1/25/14.
//  Copyright (c) 2014 Justin Brower. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaveformView : UIView
{
    //pointer to the data used for sampling
    int *data;
    
    //the number of samples available in the data
    int numberOfSamples;
    
    
}

//sets the data to be drawn
- (void)setData:(int *)data;

//starts drawing the view at 60 FPS
- (void)startDrawing;

@end
