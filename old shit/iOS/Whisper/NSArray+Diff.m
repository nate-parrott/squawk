//
//  NSArray+Diff.m
//  Squawk
//
//  Created by Nate Parrott on 2/25/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "NSArray+Diff.h"

@implementation NSArrayDiff
@end

@implementation NSArray (Diff)

NSArray* lettersFromString(NSString* s) {
    NSMutableArray* a = [NSMutableArray new];
    for (int i=0; i<s.length; i++) {
        [a addObject:[s substringWithRange:NSMakeRange(i, 1)]];
    }
    return a;
}

+(void)runArrayDiffTests {
    NSArray* testPairs = @[
                           @[@"abc", @"abcd"],
                           @[@"abc", @"ac"],
                           @[@"abcdefg", @"ade3ghi"]
                           ];
    for (NSArray* pair in testPairs) {
        NSArray* from = lettersFromString(pair[0]);
        NSArray* to = lettersFromString(pair[1]);
        for (NSArray* apair in @[@[from, to], @[to, from]]) {
            NSArray* a1 = apair[0];
            NSArray* a2 = apair[1];
            
            NSLog(@"a1: %@", [a1 componentsJoinedByString:@","]);
            NSLog(@"a2: %@", [a2 componentsJoinedByString:@","]);
            
            NSArray* diffs = [a1 diffsWithArray:a2 comparator:^BOOL(id a, id b) {
                return [a isEqual:b];
            }];
            for (NSArrayDiff* diff in diffs) {
                NSLog(@"Replace %@ with %@", NSStringFromRange(diff.range), [diff.insertedObjects componentsJoinedByString:@","]);
            }
            NSArray* reconstructed = [a1 applyDiffs:diffs];
            NSLog(@"reconstructed: %@", [reconstructed componentsJoinedByString:@","]);
            if (![[a2 componentsJoinedByString:@","] isEqual:[reconstructed componentsJoinedByString:@","]]) {
                NSLog(@"ah!");
            }
        }
    }
}

-(void)rangeOfLongestMatchingSubarrayWithArray:(NSArray*)other comparator:(NSArrayDiffComparator)comparator rangeInSelf:(NSRange*)rangeInSelf rangeInOther:(NSRange*)rangeInOther {
    int longestLength = 0;
    int indexInThisArray = 0;
    int indexInOtherArray = 0;
    for (int startInThisArray=0; startInThisArray<self.count; startInThisArray++) {
        for (int startInOtherArray=0; startInOtherArray<other.count; startInOtherArray++) {
            int len = 0;
            while (startInThisArray+len < self.count && startInOtherArray+len < other.count) {
                if (comparator(self[startInThisArray+len], other[startInOtherArray+len])) {
                    len++;
                } else {
                    break;
                }
            }
            if (len > longestLength) {
                longestLength = len;
                indexInThisArray = startInThisArray;
                indexInOtherArray = startInOtherArray;
            }
        }
    }
    *rangeInSelf = NSMakeRange(indexInThisArray, longestLength);
    *rangeInOther = NSMakeRange(indexInOtherArray, longestLength);
}

-(NSArray*)diffsWithArray:(NSArray*)other comparator:(NSArrayDiffComparator)comparator {
    NSArrayDiffer* differ = [NSArrayDiffer new];
    differ.array1 = self;
    differ.array2 = other;
    differ.comparator = comparator;
    return [differ diff];
    
    
    NSRange commonRangeInSelf, commonRangeInOther;
    [self rangeOfLongestMatchingSubarrayWithArray:other comparator:comparator rangeInSelf:&commonRangeInSelf rangeInOther:&commonRangeInOther];
    if (commonRangeInSelf.length==0) {
        NSArrayDiff* diff = [NSArrayDiff new];
        diff.range = NSMakeRange(0, self.count);
        diff.insertedObjects = other;
        return @[diff];
    }
    NSMutableArray* diffs = [NSMutableArray new];
    NSArray* selfPrefix = [self subarrayWithRange:NSMakeRange(0, commonRangeInSelf.location)];
    NSArray* otherPrefix = [other subarrayWithRange:NSMakeRange(0, commonRangeInOther.location)];
    for (NSArrayDiff* diff in [selfPrefix diffsWithArray:otherPrefix comparator:comparator]) {
        [diffs addObject:diff];
    }
    NSArray* selfSuffix = [self subarrayWithRange:NSMakeRange(commonRangeInSelf.location+commonRangeInSelf.length, self.count-commonRangeInSelf.location-commonRangeInSelf.length)];
    NSArray* otherSuffix = [other subarrayWithRange:NSMakeRange(commonRangeInOther.location + commonRangeInOther.length, other.count-commonRangeInOther.location-commonRangeInOther.length)];
    for (NSArrayDiff* diff in [selfSuffix diffsWithArray:otherSuffix comparator:comparator]) {
        diff.range = NSMakeRange(diff.range.location+commonRangeInSelf.location+commonRangeInSelf.length, diff.range.length);
        [diffs addObject:diff];
    }
    return diffs;
}

-(NSArray*)applyDiffs:(NSArray*)diffs {
    NSMutableArray* working = [self mutableCopy];
    for (NSArrayDiff* diff in diffs.reverseObjectEnumerator) {
        [working replaceObjectsInRange:diff.range withObjectsFromArray:diff.insertedObjects];
    }
    return working;
}

@end



@implementation NSArrayDiffer

-(void)findLongestCommonSubarrayBetweenRange:(NSRange)range1 range2:(NSRange)range2 result1:(NSRange*)res1 result2:(NSRange*)res2 {
    int start1 = 0;
    int start2 = 0;
    int longest = 0;
    for (int i1=0; i1<range1.length; i1++) {
        for (int i2=0; i2<range2.length; i2++) {
            int len = 0;
            while (i1+len<range1.length && i2+len<range2.length && _comparator(_array1[range1.location+i1+len], _array2[range2.location+i2+len])) {
                len++;
            };
            if (len>longest) {
                longest = len;
                start1 = i1;
                start2 = i2;
            }
        }
    }
    *res1 = NSMakeRange(range1.location + start1, longest);
    *res2 = NSMakeRange(range2.location + start2, longest);
}
-(void)getDiffsBetweenRange:(NSRange)range1 range2:(NSRange)range2 diffs:(NSMutableArray*)diffs {
    NSRange match1, match2;
    [self findLongestCommonSubarrayBetweenRange:range1 range2:range2 result1:&match1 result2:&match2];
    if (match1.length == 0) {
        NSArrayDiff* diff = [NSArrayDiff new];
        diff.range = range1;
        diff.insertedObjects = [_array2 subarrayWithRange:range2];
        if (diff.range.length>0 || diff.insertedObjects.count>0) {
            [diffs addObject:diff];
        }
    } else {
        NSRange prefix1 = NSMakeRange(range1.location, match1.location - range1.location);
        NSRange prefix2 = NSMakeRange(range2.location, match2.location - range2.location);
        [self getDiffsBetweenRange:prefix1 range2:prefix2 diffs:diffs];
        
        NSRange suffix1 = NSMakeRange(match1.location+match1.length, range1.location+range1.length-match1.location-match1.length);
        NSRange suffix2 = NSMakeRange(match2.location+match2.length, range2.location+range2.length-match2.location-match2.length);
        [self getDiffsBetweenRange:suffix1 range2:suffix2 diffs:diffs];
    }
}
-(NSArray*)diff {
    NSMutableArray* diffs = [NSMutableArray new];
    [self getDiffsBetweenRange:NSMakeRange(0, _array1.count) range2:NSMakeRange(0, _array2.count) diffs:diffs];
    return diffs;
}

@end
