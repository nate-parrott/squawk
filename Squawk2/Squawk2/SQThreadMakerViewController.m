//
//  SQThreadMakerViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQThreadMakerViewController.h"
#import "NPAddressBook.h"
#import "WSContactBoost.h"
#import "SQAPI.h"
#import "UIViewController+SoftModal.h"
#import "SQTheme.h"
#import "UITextField+PopulateSlowly.h"
#import "SQFriendsOnSquawk.h"

@interface SQThreadMakerViewController () <UITableViewDelegate, UITableViewDataSource> {
    UITextField *_newContactName, *_newContactPhone;
    
    IBOutlet UITableView* _tableView;
    
    NSMutableSet* _selectedPhones;
    
    IBOutlet UIBarButtonItem* _addThreadButton;
    
    __weak UIButton* _addContactButton;
    
    IBOutlet UIButton* _inviteFriendsButton;
}

@property(strong)NSArray* filteredThreads;

@end

@implementation SQThreadMakerViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // localization:
    _addThreadButton.title = NSLocalizedString(@"+ thread", @"Press to create a new group-squawk thread with the selected people");
    [_inviteFriendsButton setTitle:NSLocalizedString(@"Share Squawk", @"") forState:UIControlStateNormal];
    
    _selectedPhones = [NSMutableSet new];
    RAC(self, filteredThreads) = [RACObserve(self, threads) map:^id(NSArray* threads) {
        return [threads.rac_sequence filter:^BOOL(SQThread* thread) {
            return thread.phoneNumbers.count==1;
        }].array;
    }];
    [[RACObserve(self, filteredThreads) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        [_tableView reloadData];
    }];
    self.view.tintColor = self.navigationController.navigationBar.tintColor = self.navigationController.toolbar.tintColor = [SQTheme orange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepopulateDataIfNeeded) name:SQPromptAddFriend object:nil];
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
}
#pragma mark TableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) {
        return NSLocalizedString(@"New contact", @"");
    } else if (section==1) {
        return NSLocalizedString(@"Start a group squawk thread", @"");
    } else {
        return nil;
    }
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        return 3;
    } else if (section==1) {
        return _filteredThreads.count;
    }
    return 0;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        if (indexPath.row <= 1) {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
            UITextField* textField = (id)[cell viewWithTag:1];
            if (indexPath.row==0) {
                textField.placeholder = NSLocalizedString(@"Phone number", @"Enter phone # for a new contact");
                textField.keyboardType = UIKeyboardTypePhonePad;
                _newContactPhone = textField;
                _addContactButton.enabled = NO;
                textField.delegate = self;
            } else if (indexPath.row==1) {
                textField.placeholder = NSLocalizedString(@"Name (optional)", @"Name for a new contact");
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                _newContactName = textField;
                textField.returnKeyType = UIReturnKeyDone;
                textField.delegate = self;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else if (indexPath.row==2) {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell" forIndexPath:indexPath];
            UIButton* button = (id)[cell viewWithTag:2];
            [button setTitle:NSLocalizedString(@"Add contact", @"") forState:UIControlStateNormal];
            [button removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [button addTarget:self action:@selector(addContact:) forControlEvents:UIControlEventTouchUpInside];
            _addContactButton = button;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    } else if (indexPath.section==1) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        SQThread* thread = _filteredThreads[indexPath.row];
        cell.textLabel.text = thread.displayName;
        cell.accessoryType = [_selectedPhones containsObject:thread.phoneNumbers.anyObject]? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.textLabel.textColor = thread.membersAreRegistered? [UIColor blackColor] : [UIColor grayColor];
        return cell;
    }
    return nil;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        NSString* num = [_filteredThreads[indexPath.row] phoneNumbers].anyObject;
        if ([_selectedPhones containsObject:num]) {
            [_selectedPhones removeObject:num];
        } else {
            [_selectedPhones addObject:num];
        }
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        _addThreadButton.enabled = (_selectedPhones.count>1);
    }
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self prepopulateDataIfNeeded];
}
-(void)prepopulateDataIfNeeded {
    NSMutableDictionary* prepopulationData = [SQThreadMakerViewController prepopulationDict];
    if (prepopulationData[@"phone"]) {
        [_newContactPhone populateSlowlyWithText:prepopulationData[@"phone"] duration:1.0];
        [_newContactName populateSlowlyWithText:prepopulationData[@"name"] duration:1.0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_newContactName becomeFirstResponder];
            _addContactButton.enabled = YES;
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [prepopulationData removeObjectForKey:@"phone"];
            [prepopulationData removeObjectForKey:@"name"];
        });
    }
}
#pragma mark UI
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _newContactPhone) {
        NSString* digits = @"0123456789 ()-+.";
        for (int i=0; i<string.length; i++) {
            if ([digits rangeOfString:[string substringWithRange:NSMakeRange(i, 1)]].location == NSNotFound) {
                return NO;
            }
        }
        NSString* newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        _addContactButton.enabled = (newString.length >= 10);
    }
    return YES;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (_addContactButton.enabled) {
        [self addContact:nil];
    }
    return YES;
}
-(IBAction)dismiss:(id)sender {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(IBAction)createThread:(id)sender {
    [AppDelegate trackEventWithCategory:@"actions" action:@"created_multisquawk_thread" label:nil value:@(_selectedPhones.allObjects.count)];
    NSMutableArray* threadMembers = _selectedPhones.allObjects.mutableCopy;
    [threadMembers removeObject:[SQAPI currentPhone]];
    [WSContactBoost boostThreadWithPhoneNumbers:threadMembers];
    [self dismiss:nil];
}
-(IBAction)addContact:(id)sender {
    if (_newContactPhone.text.length) {
        NSString* num = [NPContact normalizePhone:_newContactPhone.text];
        NSString* name = _newContactName.text;
        [NPAddressBook createContactWithName:name phone:num info:@{} callback:^(NPContact* contact){
            [WSContactBoost boostPhoneNumber:num];
            [self dismiss:nil];
        }];
        [[SQFriendsOnSquawk shared] sendInvitesToUsersIfNecessary:@[num] prompt:[SQFriendsOnSquawk genericInvitationPrompt]];
    }
}
-(IBAction)inviteFriends:(id)sender {
    [[self.storyboard instantiateViewControllerWithIdentifier:@"InviteFriends"] presentSoftModal];
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
