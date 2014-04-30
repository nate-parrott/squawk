//
//  SQNewThreadViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/29/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQNewThreadViewController.h"
#import "SQThread.h"
#import "NPAddressBook.h"
#import "WSContactBoost.h"
#import "UIViewController+SoftModal.h"
#import "SQFriendsOnSquawk.h"
#import "UITextField+PopulateSlowly.h"

@interface SQNewThreadViewController () <UITextFieldDelegate> {
    BOOL _addUserExpanded;
    NSMutableArray* _filteredSquawkers;
    IBOutlet UIButton* _doneButton;
}

@property(strong)UITextField *phone, *name;
@property(strong)UIButton* addContactButton;

@property(strong)NSSet* selectedSquawkers;

@end

@implementation SQNewThreadViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepopulateDataIfNeeded) name:SQPromptAddFriend object:nil];
    
    self.selectedSquawkers = [NSSet new];
    
    [RACObserve(self, selectedSquawkers) subscribeNext:^(NSSet* selected) {
        _doneButton.enabled = selected.count>0;
        if (selected.count==1) {
            [_doneButton setTitle:NSLocalizedString(@"Create Squawk Thread", @"") forState:UIControlStateNormal];
        } else {
            [_doneButton setTitle:NSLocalizedString(@"Create Group Squawk", @"") forState:UIControlStateNormal];
        }
    }];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self prepopulateDataIfNeeded];
}
#pragma mark Text editing
-(void)updateAddContactButtonAvailability {
    self.addContactButton.enabled = self.phone.text.length >= 10;
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.phone) {
        NSCharacterSet* digits = [NSCharacterSet decimalDigitCharacterSet];
        for (int i=0; i<string.length; i++) {
            if (![digits characterIsMember:[string characterAtIndex:i]]) {
                return NO;
            }
        }
    }
    return YES;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.phone) {
        [self.name becomeFirstResponder];
    } else if (textField == self.name) {
        if (self.addContactButton.enabled) {
            [self addContact:nil];
        }
    }
    return YES;
}
#pragma mark Data
-(void)setSquawkers:(NSArray *)squawkers {
    _squawkers = squawkers;
    _filteredSquawkers = [_squawkers.rac_sequence filter:^BOOL(SQThread* thread) {
        return thread.numbersToDisplay.count==1;
    }].array.mutableCopy;
    NSComparisonResult (^compare)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        _SQThreadComparisonData *c1 = [obj1 compData];
        _SQThreadComparisonData *c2 = [obj2 compData];
        NSComparisonResult registration = (NSComparisonResult)c1->_registered - (NSComparisonResult)c2->_registered;
        if (registration) return -registration;
        return strcmp(c1->_name, c2->_name);
    };
    [_filteredSquawkers sortUsingComparator:compare];
    [self.tableView reloadData];
}
#pragma mark TableView
-(int)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        return _addUserExpanded? 3 : 1;
    } else if (section==1) {
        return _filteredSquawkers.count;
    }
    return 0;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = nil;
    if (indexPath.section==1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Squawker"];
        SQThread* thread = _filteredSquawkers[indexPath.row];
        cell.textLabel.text = thread.displayName;
        cell.textLabel.textColor = [thread membersAreRegistered]? [UIColor blackColor] : [UIColor grayColor];
        cell.detailTextLabel.text = [thread numbersToDisplay].firstObject;
        cell.accessoryType = [_selectedSquawkers containsObject:thread]? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.section==0) {
        if (_addUserExpanded) {
            if (indexPath.row==0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"PhoneField"];
                UITextField* textField = (id)[cell viewWithTag:1];
                self.phone = textField;
                self.phone.delegate = self;
                [textField addTarget:self action:@selector(updateAddContactButtonAvailability) forControlEvents:UIControlEventEditingChanged];
                [self updateAddContactButtonAvailability];
            } else if (indexPath.row==1) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"NameField"];
                UITextField* textField = (id)[cell viewWithTag:1];
                self.name = textField;
                self.name.delegate = self;
            } else if (indexPath.row==2) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"AddContactButton"];
                self.addContactButton = (id)[cell viewWithTag:1];
                [self.addContactButton setTitle:NSLocalizedString(@"Add contact", @"") forState:UIControlStateNormal];
                [self updateAddContactButtonAvailability];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddPhoneButton"];
            [(UIButton*)[cell viewWithTag:1] setTitle:NSLocalizedString(@"Add phone number...", @"") forState:UIControlStateNormal];
        }
    }
    return cell;
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section==1;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        SQThread* thread = _filteredSquawkers[indexPath.row];
        NSMutableSet* selected = self.selectedSquawkers.mutableCopy;
        if ([selected containsObject:thread]) {
            [selected removeObject:thread];
        } else {
            [selected addObject:thread];
        }
        self.selectedSquawkers = selected;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
#pragma mark Events
-(IBAction)showNewContactForm:(id)sender {
    _addUserExpanded = YES;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.phone becomeFirstResponder];
}
-(IBAction)addContact:(id)sender {
    if (self.phone.text) {
        NSString* num = [NPContact normalizePhone:self.phone.text];
        NSString* name = self.name.text;
        if ([name isEqualToString:@""]) name = nil;
        [NPAddressBook createContactWithName:name phone:num info:@{} callback:^(NPContact* contact){
            dispatch_async(dispatch_get_main_queue(), ^{
                _addUserExpanded = NO;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                if (contact) {
                    SQThread* newThread = [SQThread new];
                    [newThread.phoneNumbers addObject:contact.mobileNumber];
                    self.selectedSquawkers = [NSSet setWithArray:[self.selectedSquawkers.allObjects arrayByAddingObject:newThread]];
                    [_filteredSquawkers insertObject:newThread atIndex:0];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            });
        }];
        
        [[SQFriendsOnSquawk shared] sendInvitesToUsersIfNecessary:@[num] prompt:[SQFriendsOnSquawk genericInvitationPrompt]];
    }
}
-(IBAction)done:(id)sender {
    [AppDelegate trackEventWithCategory:@"actions" action:@"created_multisquawk_thread" label:nil value:@(self.selectedSquawkers.count)];
    NSMutableArray* phones = [NSMutableArray new];
    for (SQThread* thread in self.selectedSquawkers) {
        [phones addObjectsFromArray:thread.numbersToDisplay];
    }
    [WSContactBoost boostThreadWithPhoneNumbers:phones];
    
    [self dismissSoftModal];
}
#pragma mark Misc.
-(CGSize)sizeInSoftModal {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height-140);
}
-(void)prepopulateDataIfNeeded {
    NSMutableDictionary* prepopulationData = [SQNewThreadViewController prepopulationDict];
    if (prepopulationData[@"phone"]) {
        if (!_addUserExpanded) {
            [self showNewContactForm:nil];
            
            [self.phone populateSlowlyWithText:prepopulationData[@"phone"] duration:1.0];
            [self.name populateSlowlyWithText:prepopulationData[@"name"] duration:1.0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.name becomeFirstResponder];
                _addContactButton.enabled = YES;
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [prepopulationData removeObjectForKey:@"phone"];
                [prepopulationData removeObjectForKey:@"name"];
            });
        }
    }
}
+(NSMutableDictionary*)prepopulationDict {
    static NSMutableDictionary* dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary new];
    });
    return dict;
}

@end

