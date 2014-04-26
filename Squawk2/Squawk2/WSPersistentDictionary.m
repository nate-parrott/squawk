//
//  WSPersistentDictionary.m
//  Squawk
//
//  Created by Nate Parrott on 2/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WSPersistentDictionary.h"

@implementation WSPersistentDictionary

+(WSPersistentDictionary*)shared {
    static WSPersistentDictionary* shared = nil;
    if (!shared) {
        shared = [WSPersistentDictionary new];
    }
    return shared;
}
-(id)init {
    self = [super init];
    _loadedKeys = [NSMutableDictionary new];
    _dirtyKeys = [NSMutableSet new];
    _signalsForKeys = [NSMutableDictionary new];
    [[RACSignal merge:@[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil], [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillTerminateNotification object:nil]]] subscribeNext:^(id x) {
        [self save];
    }];
    return self;
}
-(NSString*)dir {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"WSPersistentDictionary"];
}
-(NSString*)pathForKey:(id)key {
    if (![key isKindOfClass:[NSString class]]) {
        key = [NSString stringWithFormat:@"%@-%lu", key, (unsigned long)[key hash]];
    }
    NSString* filename = [[key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] stringByAppendingPathExtension:@"archive"];
    return [[self dir] stringByAppendingString:filename];
}
-(id)objectForKeyedSubscript:(id<NSCopying>)key {
    if (!_loadedKeys[key]) {
        _loadedKeys[key] = [[NSFileManager defaultManager] fileExistsAtPath:[self pathForKey:key]]? [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForKey:key]] : [NSNull null];
    }
    id val = _loadedKeys[key];
    return [val isKindOfClass:[NSNull class]]? nil : val;
}
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    if (obj==nil) obj = [NSNull null];
    _loadedKeys[key] = obj;
    [self didUpdateValueForKey:key];
}
-(void)didUpdateValueForKey:(id<NSCopying>)key {
    [_dirtyKeys addObject:key];
    if (_signalsForKeys[key]) {
        [_signalsForKeys[key] sendNext:self[key]];
    }
}
-(void)save {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self dir]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self dir] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    for (id key in _dirtyKeys) {
        [NSKeyedArchiver archiveRootObject:_loadedKeys[key] toFile:[self pathForKey:key]];
    }
    [_dirtyKeys removeAllObjects];
}
-(void)reset {
    [[NSFileManager defaultManager] removeItemAtPath:[self dir] error:nil];
    [_dirtyKeys removeAllObjects];
    [_loadedKeys removeAllObjects];
    [_signalsForKeys removeAllObjects];
}
-(RACSignal*)signalForKey:(NSString*)key {
    RACReplaySubject* s = _signalsForKeys[key];
    if (!s) {
        s = [RACReplaySubject replaySubjectWithCapacity:1];
        _signalsForKeys[key] = s;
        [s sendNext:self[key]];
    }
    return s;
}
-(id)getObjectForKey:(id)key fallback:(id(^)())fallback {
    id val = self[key];
    if (!val) {
        self[key] = fallback();
    }
    return self[key];
}

@end
