//
//  WSMainViewController.h
//  Whisper
//
//  Created by Nate Parrott on 1/22/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NPAddressBook.h"
#import "WSMessageSender.h"
#import <ReactiveCocoa.h>
#import "WSSquawkRecorder.h"
#import "WSConcentricCirclesViewAdvancedHD2014.h"
#import "WSSquawkerCell.h"
#import "WSSingleCellTableView.h"

NSString* WSContentDidReload;

@interface WSMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
    
    RACSubject* _activeCellState; // either WSCellStatePlayback, WSCellStateRecording, or WSCellStateSilent
    WSCellState _lastActiveCellState;
    RACReplaySubject* _activeCell;
    
    NPAddressBook* _addressBook;
    
    BOOL _loadInProgress;
    
    BOOL _needsReloadLater;
    
    RACSubject* _currentUser;
    RACReplaySubject* _contacts;
    RACSubject* _searchQuery;
    
    RACSubject* _microphoneAuthorization;
    
    NSError* _displayError;
    NSMutableArray* _senders; // already sorted, filtered, etc
    
    IBOutlet WSSingleCellTableView* _multisquawkControlRow;
    
    NSMutableArray* _recentSquawks;
    
    IBOutlet UIImageView* _focusTriangle;
    IBOutlet NSLayoutConstraint* _focusTriangleOffsetConstraint;
    CGFloat _focusTriangleInitialTopOffset;
}

@property(strong)IBOutlet UITableView* tableView;
@property(strong)IBOutlet UILabel* errorLabel;

-(IBAction)enterSearchMode:(id)sender;
@property(strong)IBOutlet UISearchBar* searchBar;
@property(nonatomic)BOOL searchMode;

@property(strong)IBOutlet UIView* warningMessageContainer;
@property(strong)IBOutlet UILabel* warningMessageLabel;

@property CGPoint contentOffset; // slow-updating

@property(nonatomic)BOOL multisquawkMode;

-(void)cellStateUpdated;
-(void)cancelAllBut:(WSSquawkerCell*)cell;

@property(nonatomic)CGFloat focusTriangleTopOffset;

-(void)highlightCell:(UITableViewCell*)cell;

@property(strong)RACSignal* cellForRaiseToSquawk;

+(RACReplaySubject*)mostRecentSendersOrError;

@end
