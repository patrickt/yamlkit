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

inline YKMark YKMakeMark(NSUInteger line, NSUInteger column, NSUInteger idx)
{
    YKMark results = {line, column, idx};
    return results;
}

@implementation YKUnknownNode

+ (id)unknownNodeWithStringValue:(NSString *)aStringValue implicitTag:(YKTag *)aImplicitTag
                       explicitTag:(YKTag *)aExplicitTag position:(YKRange)aPosition
{
    return [[[self alloc] initWithStringValue:aStringValue implicitTag:aImplicitTag explicitTag:aExplicitTag
                                     position:aPosition] autorelease];
}

- (id)initWithStringValue:(NSString *)aStringValue implicitTag:(YKTag *)aImplicitTag explicitTag:(YKTag *)aExplicitTag
                    position:(YKRange)aPosition
{
    if (!(self = [super init]))
        return nil;

    stringValue = [aStringValue copy];
    implicitTag = [aImplicitTag retain];
    explicitTag = [aExplicitTag retain];
    memcpy(&position, &aPosition, sizeof(YKRange));

    return self;
}

- (void)dealloc
{
    [stringValue release], stringValue = nil;
    [implicitTag release], implicitTag = nil;
    [explicitTag release], explicitTag = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{!%@ %@ (%d:%d),(%d:%d)}", explicitTag, stringValue,
            position.start.line, position.start.column, position.end.line, position.end.column];
}

@synthesize position;
@synthesize implicitTag;
@synthesize explicitTag;
@synthesize stringValue;

@end
