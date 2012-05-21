//
//  YKNativeTagManager.m
//  YAMLKit
//
//  Created by Faustino Osuna on 10/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YKNativeTagManager.h"
#import "YKConstants.h"
#import "NSString+YAMLKit.h"
#import "NSData+Base64.h"

// !!int: tag:yaml.org,2002:int ( http://yaml.org/type/int.html )
#define YAML_INT_BINARY_REGEX           @"^([-+])?0b([0-1_]+)$"
#define YAML_INT_OCTAL_REGEX            @"^[-+]?0[0-7_]+$"
#define YAML_INT_DECIMAL_REGEX          @"^[-+]?(?:0|[1-9][0-9_]*)$"
#define YAML_INT_HEX_REGEX              @"^[-+]?0x[0-9a-fA-F_]+$"
#define YAML_INT_SEXAGESIMAL_REGEX      @"^([-+])?(([1-9][0-9_]*)(:[0-5]?[0-9])+)$"

// !!float: tag:yaml.org,2002:float ( http://yaml.org/type/float.html )
#define YAML_FLOAT_DECIMAL_REGEX        @"^[-+]?(?:[0-9][0-9_]*)?\\.[0-9_]*(?:[eE][-+][0-9]+)?$"
#define YAML_FLOAT_SEXAGESIMAL_REGEX    @"^[-+]?[0-9][0-9_]*(?::[0-5]?[0-9])+\\.[0-9_]*$"
#define YAML_FLOAT_INFINITY_REGEX       @"^[-+]?\\.(?:inf|Inf|INF)$"
#define YAML_FLOAT_NAN_REGEX            @"^\\.(?:nan|NaN|NAN)$"

// !!bool: tag:yaml.org,2002:bool ( http://yaml.org/type/bool.html )
#define YAML_BOOL_TRUE_REGEX            @"^(?:[Yy](?:es)?|YES|[Tt]rue|TRUE|[Oo]n|ON)$"
#define YAML_BOOL_FALSE_REGEX           @"^(?:[Nn]o?|NO|[Ff]alse|FALSE|[Oo]ff|OFF)$"

// !!null: tag:yaml.org,2002:null ( http://yaml.org/type/null.html )
#define YAML_NULL_REGEX                 @"^(?:~|[Nn]ull|NULL|)$"

// !!timestamp: tag:yaml.org,2002:timestamp ( http://yaml.org/type/timestamp.html )
#define YAML_TIMESTAMP_YMD_REGEX        @"^(?:[0-9]{4}-[0-9]{2}-[0-9]{2})$"
#define YAML_TIMESTAMP_YMDTZ_REGEX      @"^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})(?:[Tt]|[ \\t]+)([0-9]{1,2}):([0-9]{2}):([0-9]{2})(?:\\.([0-9]*))?[ \\t]*(?:Z|(?:([-+][0-9]{1,2})(?::([0-9]{2}))?))?$"

@interface YKNativeTagManager (YKNativeTagManagerMethods)

- (void)_addBuiltinTags;

@end

@implementation YKNativeTagManager

static YKNativeTagManager *__sharedManager = nil;

+ (id)sharedManager
{
    if (__sharedManager)
        return __sharedManager;

    @synchronized([self class]) {
        __sharedManager = [[self alloc] init];
    }

    return __sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    if (__sharedManager)
        return nil;

    @synchronized(self) {
        __sharedManager = [super allocWithZone:zone];
    }

    return __sharedManager;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;

    NSMutableDictionary *mutableBuiltInTags = [NSMutableDictionary dictionary];

    // !!int: tag:yaml.org,2002:int ( http://yaml.org/type/int.html )
    YKRegexTag *intTag = [[[YKRegexTag alloc] initWithURI:YKIntegerTagDeclaration delegate:self] autorelease];
    [intTag addRegexDeclaration:YAML_INT_BINARY_REGEX hint:[NSNumber numberWithInt:2]];
    [intTag addRegexDeclaration:YAML_INT_OCTAL_REGEX hint:[NSNumber numberWithInt:8]];
    [intTag addRegexDeclaration:YAML_INT_DECIMAL_REGEX hint:[NSNumber numberWithInt:10]];
    [intTag addRegexDeclaration:YAML_INT_HEX_REGEX hint:[NSNumber numberWithInt:16]];
    [intTag addRegexDeclaration:YAML_INT_SEXAGESIMAL_REGEX hint:[NSNumber numberWithInt:60]];
    [mutableBuiltInTags setObject:intTag forKey:YKIntegerTagDeclaration];

    // !!float: tag:yaml.org,2002:float ( http://yaml.org/type/float.html )
    YKRegexTag *floatTag = [[[YKRegexTag alloc] initWithURI:YKFloatTagDeclaration delegate:self] autorelease];
    [floatTag addRegexDeclaration:YAML_FLOAT_DECIMAL_REGEX hint:[NSNumber numberWithInt:10]];
    [floatTag addRegexDeclaration:YAML_FLOAT_SEXAGESIMAL_REGEX hint:[NSNumber numberWithInt:60]];
    [floatTag addRegexDeclaration:YAML_FLOAT_INFINITY_REGEX hint:[NSNumber numberWithInt:-1]];
    [floatTag addRegexDeclaration:YAML_FLOAT_NAN_REGEX hint:[NSDecimalNumber notANumber]];
    [mutableBuiltInTags setObject:floatTag forKey:YKFloatTagDeclaration];

    // !!bool: tag:yaml.org,2002:bool ( http://yaml.org/type/bool.html )
    YKRegexTag *boolTag = [[[YKRegexTag alloc] initWithURI:YKBooleanTagDeclaration delegate:self] autorelease];
    [boolTag addRegexDeclaration:YAML_BOOL_TRUE_REGEX hint:(id)kCFBooleanTrue];
    [boolTag addRegexDeclaration:YAML_BOOL_FALSE_REGEX hint:(id)kCFBooleanFalse];
    [mutableBuiltInTags setObject:boolTag forKey:YKBooleanTagDeclaration];

    // !!null: tag:yaml.org,2002:null ( http://yaml.org/type/null.html )
    YKRegexTag *nullTag = [[[YKRegexTag alloc] initWithURI:YKNullTagDeclaration delegate:self] autorelease];
    [nullTag addRegexDeclaration:YAML_NULL_REGEX hint:[NSNull null]];
    [mutableBuiltInTags setObject:nullTag forKey:YKNullTagDeclaration];

    // !!timestamp: tag:yaml.org,2002:timestamp ( http://yaml.org/type/timestamp.html )
    YKRegexTag *timestampTag = [[[YKRegexTag alloc] initWithURI:YKTimeStampTagDeclaration delegate:self] autorelease];
    [timestampTag addRegexDeclaration:YAML_TIMESTAMP_YMD_REGEX hint:(id)kCFBooleanTrue];
    [timestampTag addRegexDeclaration:YAML_TIMESTAMP_YMDTZ_REGEX hint:(id)kCFBooleanFalse];
    [mutableBuiltInTags setObject:timestampTag forKey:YKTimeStampTagDeclaration];

    // !!str: tag:yaml.org,2002:str ( http://yaml.org/type/str.html )
    YKTag *stringTag = [[[YKTag alloc] initWithURI:YKStringTagDeclaration delegate:self] autorelease];
    [mutableBuiltInTags setObject:stringTag forKey:YKStringTagDeclaration];

    // !!binary: tag:yaml.org,2002:binary ( http://yaml.org/type/binary.html )
    YKTag *binaryTag = [[[YKTag alloc] initWithURI:YKBinaryTagDeclaration delegate:self] autorelease];
    [mutableBuiltInTags setObject:binaryTag forKey:YKBinaryTagDeclaration];

    tagsByName = [[NSDictionary alloc] initWithDictionary:mutableBuiltInTags];

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
	
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (void)release
{
    // Do nothing
}

- (id)autorelease
{
    return self;
}

- (id)tag:(YKTag *)tag decodeFromString:(NSString *)stringValue extraInfo:(NSDictionary *)extraInfo
{
    id hint = [extraInfo valueForKey:@"hint"];
    NSArray *components = [extraInfo valueForKey:@"components"];

    if (tag == [tagsByName valueForKey:YKIntegerTagDeclaration]) {
        int base = [hint intValue];
        if (base == 2) {
            return [NSNumber numberWithInteger:([[[components objectAtIndex:0] objectAtIndex:1] isEqualToString:@"-"] ? -1 : 1) *
                    [[[components objectAtIndex:0] objectAtIndex:2] intValueFromBase:2]];
        } else if (base == 60) {
            NSInteger resultValue = 0;
            for (NSString *component in [stringValue componentsSeparatedByString:@":"]) {
                resultValue = (resultValue * 60) + [component intValueFromBase:10];
            }
            return [NSNumber numberWithInteger:resultValue];
        } else {
            return [NSNumber numberWithInteger:[stringValue intValueFromBase:base]];
        }
    } else if (tag == [tagsByName valueForKey:YKFloatTagDeclaration]) {
        int base = [hint intValue];
        double resultValue = 0;
        switch (base) {
            case -1:
                if ([stringValue hasPrefix:@"-"])
                    return (id)kCFNumberPositiveInfinity;
                else
                    return (id)kCFNumberNegativeInfinity;
                break;
            case 10:
                return [NSDecimalNumber decimalNumberWithString:[stringValue stringByReplacingOccurrencesOfString:@"_"
                                                                                                       withString:@""]];
                break;
            case 60:
                for (NSString *component in [[stringValue stringByReplacingOccurrencesOfString:@"_" withString:@""]
                                             componentsSeparatedByString:@":"]) {
                    resultValue = (resultValue * 60.0f) + [component doubleValue];
                }
                return [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithDouble:resultValue] decimalValue]];
                break;
            default:
                return nil;
                break;
        }
    } else if (tag == [tagsByName valueForKey:YKBooleanTagDeclaration] ||
               tag == [tagsByName valueForKey:YKNullTagDeclaration]) {
        return hint;
    } else if (tag == [tagsByName valueForKey:YKTimeStampTagDeclaration]) {
        // Timestamp
        if (hint == (id)kCFBooleanTrue)
            return [NSDate dateWithString:[stringValue stringByAppendingFormat:@" 00:00:00 +0000"]];

        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setYear:[[[components objectAtIndex:0] objectAtIndex:1] intValue]];
        [dateComponents setMonth:[[[components objectAtIndex:0] objectAtIndex:2] intValue]];
        [dateComponents setDay:[[[components objectAtIndex:0] objectAtIndex:3] intValue]];
        [dateComponents setHour:[[[components objectAtIndex:0] objectAtIndex:4] intValue]];
        [dateComponents setMinute:[[[components objectAtIndex:0] objectAtIndex:5] intValue]];
        [dateComponents setSecond:[[[components objectAtIndex:0] objectAtIndex:6] intValue]];

        NSInteger fractional = [[[components objectAtIndex:0] objectAtIndex:7] intValue];

        NSInteger deltaFromGMTInSeconds = ([[[components objectAtIndex:0] objectAtIndex:8] intValueFromBase:10] * 360) +
        ([[[components objectAtIndex:0] objectAtIndex:9] intValue] * 60);

        NSTimeZone *timeZone = nil;
        if (deltaFromGMTInSeconds != 0)
            timeZone = [NSTimeZone timeZoneForSecondsFromGMT:deltaFromGMTInSeconds];
        else
            timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        [gregorian setTimeZone:timeZone];

        NSDate *resultDate = [gregorian dateFromComponents:dateComponents];
        [gregorian release];
        [dateComponents release];

        // This is not the most elegant way of doing it...but update the date with the fractional value
        if (fractional > 0) {
            NSTimeInterval fractionalInterval = (double)fractional / pow(10.0, floor(log10((double)fractional))+1.0);
            resultDate = [resultDate dateByAddingTimeInterval:fractionalInterval];
        }
        return resultDate;
    }
    return nil;
}

- (id)tag:(YKTag *)tag castValue:(id)value fromTag:(YKTag *)castingTag
{
    if (!castingTag) {
        if (tag == [tagsByName valueForKey:YKStringTagDeclaration])
            return value;
        else if (tag == [tagsByName valueForKey:YKNullTagDeclaration])
            return [NSNull null];
        else if (tag == [tagsByName valueForKey:YKBinaryTagDeclaration])
            return [NSData dataFromBase64String:value];
    }
    return nil;
}

- (id)tag:(YKTag *)tag castValue:(id)value toTag:(YKTag *)castingTag
{
    // Try to cast results to an 'Integer'
    if (castingTag == [tagsByName valueForKey:YKIntegerTagDeclaration]) {
        if (tag == [tagsByName valueForKey:YKNullTagDeclaration])
            return [NSNumber numberWithInt:0];
        if ([value isKindOfClass:[NSNumber class]])
            return [NSNumber numberWithInt:[value intValue]];
    // Try to cast results to a 'Float'
    } else if (castingTag == [tagsByName valueForKey:YKFloatTagDeclaration]) {
        if (value == [NSNull null])
            return [NSNumber numberWithDouble:0.0];
        if ([value isKindOfClass:[NSNumber class]])
            return [NSNumber numberWithDouble:[value doubleValue]];
    // Try to cast results to a 'Boolean'
    } else if (castingTag == [tagsByName valueForKey:YKBooleanTagDeclaration]) {
        if (value == [NSNull null])
            return (id)kCFBooleanFalse;
        if ([value isKindOfClass:[NSNumber class]])
            return ([value doubleValue] > 0 ? (id)kCFBooleanTrue : (id)kCFBooleanFalse);
    }
    return nil;
}

@synthesize tagsByName;

@end
