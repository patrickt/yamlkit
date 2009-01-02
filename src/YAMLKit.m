//
//  YAMLKit.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/30/08.
//  Copyright 2008 Patrick Thomson. All rights reserved.
//

#import "YAMLKit.h"

@implementation YAMLKit

+ (id)load:(NSString *)str
{
    YKParser *p = [[[YKParser alloc] initWithString:str] autorelease];
    NSArray *result = [p parse];
    // If parse returns a one-element array, extract it.
    if([result count] == 1) {
        return [result objectAtIndex:0];
    }
    return result;
}

+ (NSString *)dump:(id)object
{
    YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
    [e emitItem:object];
    return [e emittedString];
}



@end
