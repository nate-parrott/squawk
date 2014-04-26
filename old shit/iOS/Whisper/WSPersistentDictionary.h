//
//  WSPersistentDictionary.h
//  Squawk
//
//  Created by Nate Parrott on 2/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

/*
 like NSUserDefaults, but stores every key in a different file
 */

@interface WSPersistentDictionary : NSObject {
    NSMutableDictionary* _loadedKeys;
    NSMutableSet* _dirtyKeys;
    NSMutableDictionary* _signalsForKeys;
}

+(WSPersistentDictionary*)shared;

-(id)objectForKeyedSubscript:(id<NSCopying>)key;
-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
-(void)didUpdateValueForKey:(NSString*)key;

-(void)reset;

-(RACSignal*)signalForKey:(NSString*)key;

@end
