//
//  WSToastNotificationView.m
//  Squawk
//
//  Created by Nate Parrott on 1/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSToastNotificationView.h"

@implementation WSToastNotificationView

+(void)showToastMessage:(NSString*)message inView:(UIView*)container {
    WSToastNotificationView* view = [[UINib nibWithNibName:@"WSToastNotificationView" bundle:nil] instantiateWithOwner:nil options:nil][0];
    view.label.text = message;
    [container addSubview:view];
    view.frame = CGRectMake(0, -view.frame.size.height, container.bounds.size.width, view.frame.size.height);
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        view.frame = CGRectMake(0, 0, container.bounds.size.width, view.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view dismiss];
    });
}

-(IBAction)tapped:(id)sender {
    [self dismiss];
}

-(void)dismiss {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.frame = CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
