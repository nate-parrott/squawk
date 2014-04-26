//
//  WSToastNotificationView.h
//  Squawk
//
//  Created by Nate Parrott on 1/26/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSToastNotificationView : UIView {
    
}

@property(strong)IBOutlet UILabel* label;

+(void)showToastMessage:(NSString*)message inView:(UIView*)container;

-(IBAction)tapped:(id)sender;

@end
