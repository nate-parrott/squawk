//
//  WSBetaUIViewController.h
//  Squawk
//
//  Created by Nate Parrott on 2/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQExpandingTableView.h"
#import <ReactiveCocoa.h>
#import "NPAddressBook.h"
#import "WSSquawkerCell.h"

@interface WSBetaUIViewController : UIViewController <SQExpandingTableViewDelegate, UISearchBarDelegate> {
    WSCellState _lastActiveCellState;
    
    NPAddressBook* _addressBook;
    
    BOOL _loadInProgress;
    
    BOOL _needsReloadLater;
    
    RACSubject* _currentUser;
    RACReplaySubject* _contacts;
    RACSubject* _searchQuery;
    RACSubject* _activeCellState; // either WSCellStatePlayback, WSCellStateRecording, or WSCellStateSilent
    
    RACSubject* _microphoneAuthorization;
    
    NSError* _displayError;
    NSArray* _senders; // already sorted, filtered, etc
    
    UISearchBar* _searchBar;
    
    NSMutableArray* _recentSquawks;
}

@property(strong)SQExpandingTableView* table;

@property(strong)UIView* warningMessageContainer;
@property(strong)UILabel* warningMessageLabel;

@end
