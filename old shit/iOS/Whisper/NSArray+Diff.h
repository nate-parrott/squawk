//
//  NSArray+Diff.h
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^NSArrayDiffComparator)(id a, id b);
@interface NSArrayDiff : NSObject

@property NSRange range;
@property(strong)NSArray* insertedObjects;

@end


@interface NSArray (Diff)

-(NSArray*)diffsWithArray:(NSArray*)other comparator:(NSArrayDiffComparator)comparator;
-(NSArray*)applyDiffs:(NSArray*)diffs;
+(void)runArrayDiffTests;

@end

@interface NSArrayDiffer : NSObject {
}

@property(strong) NSArrayDiffComparator comparator;
@property(strong)NSArray *array1, *array2;
-(NSArray*)diff;

@end
