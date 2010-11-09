//
//  YKTag.m
//  YAMLKit
//
//  Created by Faustino Osuna on 9/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YKTag.h"
#import "RegexKitLite.h"
#import "YKUnknownNode.h"

@interface YKTag (YKTagPrivateMethods)

// Following method is used for internal subclasses.  This method allows for subclasses to determine how a stringValue
// should be decoded.  This method is called from -decodeFromString:explicitTag:.  -decodeFromString:explictTag: attempts
// to decode a string value using -_internalDecodeFromString:extraInfo:, if a value was successfully decoded it then
// attempts to cast the value (if an explicitTag was specified) using -castValue:toTag:.  If -castValue:toTag: is unsuccessful
// then -castValue:toTag: attempts to call the explicit's tag -castValue:fromTag:.  If the explicit tag does not return a value
// then the system cannot cast and the value is returned as an YKUnknownNode vice a native scalar value.
- (id)_internalDecodeFromString:(NSString *)stringValue extraInfo:(NSDictionary *)extraInfo;

@end

@implementation YKTag;

- (id)initWithURI:(NSString *)aURI delegate:(id)aDelegate
{
    if (!aURI) {
        [self release];
        return nil;
    }

    if (!(self = [super init]))
        return nil;

    verbatim = [aURI copy];
    shorthand = [[[aURI componentsSeparatedByString:@":"] lastObject] copy];
    delegate = aDelegate;

    return self;
}

- (void)dealloc
{
    [verbatim release], verbatim = nil;
    [shorthand release], shorthand = nil;
    delegate = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), verbatim];
}

- (id)decodeFromString:(NSString *)stringValue explicitTag:(YKTag *)explicitTag
{
    // If string cannot be decoded, nil is returned.  If the string was decoded and cannot be casted, YKUknownNode is returned
    id resultingValue = [self _internalDecodeFromString:stringValue
                                              extraInfo:[NSDictionary dictionaryWithObject:(explicitTag ? (id)explicitTag : (id)[NSNull null])
                                                                                    forKey:@"explicitTag"]];
    if (!resultingValue || !explicitTag || self == explicitTag)
        return resultingValue;

    id castedValue = [self castValue:resultingValue toTag:explicitTag];
    if (castedValue)
        return castedValue;

    return [YKUnknownNode unknownNodeWithStringValue:stringValue implicitTag:self explicitTag:explicitTag
                                            position:YKMakeRange(YKMakeMark(0, 0, 0),YKMakeMark(0, 0, 0))];
}

- (id)_internalDecodeFromString:(NSString *)stringValue extraInfo:(NSDictionary *)extraInfo
{
    if (![delegate respondsToSelector:@selector(tag:decodeFromString:extraInfo:)])
        return nil;
    return [(id<YKTagDelegate>)delegate tag:self decodeFromString:stringValue extraInfo:extraInfo];
}

- (id)castValue:(id)value fromTag:(YKTag *)castingTag
{
    if (![delegate respondsToSelector:@selector(tag:castValue:fromTag:)])
        return nil;
    return [(id<YKTagDelegate>)delegate tag:self castValue:value fromTag:castingTag];
}

- (id)castValue:(id)value toTag:(YKTag *)castingTag
{
	
    id resultingValue = [castingTag castValue:value fromTag:self];
    if (resultingValue)
       return resultingValue;

    if (![delegate respondsToSelector:@selector(tag:castValue:toTag:)])
        return nil;
    return [(id<YKTagDelegate>)delegate tag:self castValue:value toTag:castingTag];
}

@synthesize verbatim;
@synthesize shorthand;
@synthesize delegate;

@end

@interface YKRegexTag (YKRegexTagPrivateMethods)

- (NSArray *)_findRegexThatMatchesStringValue:(NSString *)stringValue hint:(id*)hint;

@end

@implementation YKRegexTag : YKTag

- (id)initWithURI:(NSString *)aURI delegate:(id)aDelegate
{
    if (!(self = [super initWithURI:aURI delegate:aDelegate]))
        return nil;

    regexDeclarations = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc
{
    [regexDeclarations release], regexDeclarations = nil;
    [super dealloc];
}

- (void)addRegexDeclaration:(NSString *)regex hint:(id)hint;
{
    [regexDeclarations setValue:(hint ? hint : [NSNull null]) forKey:regex];
}

- (id)_internalDecodeFromString:(NSString *)stringValue extraInfo:(NSDictionary *)extraInfo
{
    id hint = nil;
    NSArray *components = [self _findRegexThatMatchesStringValue:stringValue hint:&hint];
    if (!components)
        return nil;

    NSMutableDictionary *scopeMutableExtraInfo = [NSMutableDictionary dictionaryWithDictionary:extraInfo];
    [scopeMutableExtraInfo setValue:components forKey:@"components"];
    [scopeMutableExtraInfo setValue:(hint ? hint : [NSNull null]) forKey:@"hint"];
    NSDictionary *scopeExtraInfo = [NSDictionary dictionaryWithDictionary:scopeMutableExtraInfo];

    return [super _internalDecodeFromString:stringValue extraInfo:scopeExtraInfo];
}

- (NSArray *)_findRegexThatMatchesStringValue:(NSString *)stringValue hint:(id*)hint
{
    NSArray *components = nil;
    for (NSString *regex in regexDeclarations) {
        components = [stringValue arrayOfCaptureComponentsMatchedByRegex:regex];
        if ([components count] > 0) {
            if (hint)
                *hint = [regexDeclarations valueForKey:regex];
            return components;
        }
    }
    return nil;
}

@end
