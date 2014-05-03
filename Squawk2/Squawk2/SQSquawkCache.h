//
//  SQSquawkCache.h
//  Squawk2
//
//  Created by Nate Parrott on 3/4/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQSquawkCache : NSObject

+(SQSquawkCache*)shared;
@property(strong)NSArray* squawks;
@property(strong)NSError* error;

+(void)dataUpdated;

-(void)fetch;
-(void)preloadSquawkAudioWithID:(NSString*)squawkID;
-(void)getDataForSquawk:(NSDictionary*)squawk callback:(void(^)(NSData* data, NSError* error))callback;
-(void)deleteCachesForSquawkWithID:(NSString*)squawkID;

@property BOOL fetchInProgress;

-(void)pollIfNeeded;

@end
