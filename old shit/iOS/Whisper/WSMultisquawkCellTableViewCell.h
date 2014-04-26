//
//  WSMultisquawkCellTableViewCell.h
//  Squawk
//
//  Created by Nate Parrott on 2/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSSquawkerCell.h"

NSString* WSShouldQuitMultisquawkMode;

@interface WSMultisquawkCellTableViewCell : WSSquawkerCell {
    
}

-(IBAction)endMultisquawkMode:(id)sender;

+(NSMutableSet*)multisquawkSelectedPhoneNumbers;

@end
