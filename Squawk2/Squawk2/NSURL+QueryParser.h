//
//  NSURL+QueryParser.h
//  Squawk2
//
//  Created by Nate Parrott on 4/3/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

// from http://stackoverflow.com/questions/3997976/parse-nsurl-query-property via https://gist.github.com/mrtj/5613206 

#import <Foundation/Foundation.h>

@interface NSURL (QueryParser)

-(NSDictionary*)queryDictionary;

@end
