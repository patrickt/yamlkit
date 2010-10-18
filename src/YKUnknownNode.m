//
//  YKUnknownNode.m
//  YAMLKit
//
//  Created by Faustino Osuna on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YKUnknownNode.h"

inline YKRange YKMakeRange(YKMark start, YKMark end)
{
    YKRange results = {start,end};
    return results;
}

inline YKMark YKMakeMark(NSUInteger line, NSUInteger column, NSUInteger index)
{
    YKMark results = {line, column, index};
    return results;
}

@implementation YKUnknownNode

+ (id)unknownNodeWithStringValue:(NSString *)aStringValue resolvedTag:(NSString *)aResolvedTag
                       castedTag:(NSString *)aCastedTag position:(YKRange)aPosition
{
    return [[[self alloc] initWithStringValue:aStringValue resolvedTag:aResolvedTag castedTag:aCastedTag
                                     position:aPosition] autorelease];
}

- (id)initWithStringValue:(NSString *)aStringValue resolvedTag:(NSString *)aResolvedTag castedTag:(NSString *)aCastedTag
                    position:(YKRange)aPosition
{
    if (!(self = [super init]))
        return nil;

    stringValue = [aStringValue copy];
    resolvedTag = [aResolvedTag copy];
    castedTag = [aCastedTag copy];
    memcpy(&position, &aPosition, sizeof(YKRange));

    return self;
}

- (void)dealloc
{
    [stringValue release], stringValue = nil;
    [resolvedTag release], resolvedTag = nil;
    [castedTag release], castedTag = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{!<%@> %@ (%d:%d),(%d:%d)}", castedTag, stringValue,
            position.start.line, position.start.column, position.end.line, position.end.column];
}

@synthesize position;
@synthesize resolvedTag;
@synthesize castedTag;
@synthesize stringValue;

@end
