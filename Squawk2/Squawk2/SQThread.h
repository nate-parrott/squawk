//
//  SQThread.h
//  Squawk2
//
//  Created by Nate Parrott on 3/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const SQThreadUpdatedNotification;
NSString *const SQSquawkListenedStatusChangedNotification; // the 'object' is the _id of the squawk

typedef struct {
    NSTimeInterval _date; // descending
    unsigned char _registered; // descending
    char* _name; // ascending
    NSUInteger _hash; // ascending
} _SQThreadComparisonData;

@interface SQThread : NSObject {
    BOOL _hasCompData;
    _SQThreadComparisonData _compData;
}

-(id)init;
@property(strong)NSMutableSet* phoneNumbers; // includes current user
@property(strong)NSMutableArray* contacts;
@property(strong)NSMutableArray* squawks;

-(NSString*)identifier;
-(NSString*)displayName;
-(NSString*)veryShortName;

-(NSArray*)unread;

-(NSArray*)numbersToDisplay;

+(NSArray*)makeThreadsFromRecentSquawks:(NSArray*)squawks contacts:(NSArray*)contacts;
+(NSArray*)searchThreads:(NSArray*)threads withQuery:(NSString*)query;
+(NSArray*)sortThreadsIntoSections:(NSArray*)threads;

+(void)listenedToSquawk:(NSMutableDictionary *)squawk;
+(BOOL)isSquawkListened:(NSMutableDictionary*)squawk;

// this cross-references a list of squawks coming from the server and the local cache of listened squawks, and re-sends the 'listened' call to any squawks are marked as 'listened' on the client but not the server
+(void)makeSureListenedSquawksAreKnownOnServer:(NSArray*)squawksFromServer;

-(BOOL)membersAreRegistered;

@property(strong,nonatomic)NSString* stringForSearching;

// ALWAYS includes the current phone # (it'll be added if not present)
+(NSString*)identifierForThreadWithPhoneNumbers:(NSArray*)numbers;

-(_SQThreadComparisonData*)compData;

+(NSString*)nameForNumber:(NSString*)number;
+(NSString*)shortNameForNumber:(NSString*)number;

+(void)deleteSquawks:(NSArray*)squawks intervalBetweenEach:(NSTimeInterval)delay;

+(NSDictionary*)specialNames;

@end
