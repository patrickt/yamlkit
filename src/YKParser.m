//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "yaml.h"
#import "YKParser.h"
#import "YKConstants.h"
#import "RegexKitLite.h"
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

@interface YKParser (YKParserPrivateMethods)

- (id)_interpretObjectFromEvent:(yaml_event_t)event;
- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p;
- (void)_destroy;

@end

@implementation YKParser

@synthesize isReadyToParse=readyToParse;

- (id)init {
    if (!(self = [super init]))
        return nil;

    opaque_parser = malloc(sizeof(yaml_parser_t));
    if (!opaque_parser || !yaml_parser_initialize(opaque_parser))
    {
        [self release];
        return nil;
    }

    return self;
}

- (void)reset
{
    [self _destroy];
    yaml_parser_initialize(opaque_parser);
}

- (BOOL)readFile:(NSString *)path
{
    if (!path || [path isEqualToString:@""])
        return FALSE;

    [self reset];
    fileInput = fopen([path fileSystemRepresentation], "r");
    readyToParse = ((fileInput != NULL) && (yaml_parser_initialize(opaque_parser)));
    if (readyToParse)
        yaml_parser_set_input_file(opaque_parser, fileInput);
    return readyToParse;
}

- (BOOL)readString:(NSString *)str
{
    if (!str || [str isEqualToString:@""])
        return FALSE;

    [self reset];
    stringInput = [str UTF8String];
    readyToParse = yaml_parser_initialize(opaque_parser);
    if (readyToParse)
        yaml_parser_set_input_string(opaque_parser, (const unsigned char *)stringInput, [str length]);
    return readyToParse;
}

- (NSArray *)parse
{
    return [self parseWithError:NULL];
}

- (NSArray *)parseWithError:(NSError **)e
{
    if (!readyToParse) {
        if (e != NULL)
            *e = [self _constructErrorFromParser:NULL];
        return nil;
    }

    yaml_event_t event;
    BOOL done = NO;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];

    while (!done) {
        if (!yaml_parser_parse(opaque_parser, &event)) {
            if (e != NULL) {
                *e = [self _constructErrorFromParser:opaque_parser];
            }
            // An error occurred, set the stack to null and exit loop
            stack = nil;
            done = TRUE;
        } else {
            switch (event.type) {
                case YAML_SCALAR_EVENT:
                    temp = [stack lastObject];
                    if ([temp isKindOfClass:[NSDictionary class]]) {
                        [stack addObject:[NSString stringWithUTF8String:(const char *)event.data.scalar.value]];
                    } else {
                        obj = [self _interpretObjectFromEvent:event];
                        if ([temp isKindOfClass:[NSArray class]]) {
                            [temp addObject:obj];
                        } else {
                            [temp retain];
                            [stack removeLastObject];

                            if (![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]) {
                                if (e != NULL) {
                                    *e = [self _constructErrorFromParser:NULL];
                                }
                                // An error occurred, set the stack to null and exit loop
                                done = TRUE;
                                stack = nil;
                            } else {
                                [[stack lastObject] setObject:obj forKey:temp];
                            }
                            [temp release];
                        }
                    }
                    break;
                case YAML_SEQUENCE_START_EVENT:
                    [stack addObject:[NSMutableArray array]];
                    break;
                case YAML_MAPPING_START_EVENT:
                    [stack addObject:[NSMutableDictionary dictionary]];
                    break;
                case YAML_SEQUENCE_END_EVENT:
                case YAML_MAPPING_END_EVENT:
                    temp = [[stack lastObject] retain];
                    [stack removeLastObject];

                    id last = [stack lastObject];
                    if (last == nil) {
                        [stack addObject:temp];
                        break;
                    } else if ([last isKindOfClass:[NSArray class]]) {
                        [last addObject:temp];
                    } else if ([last isKindOfClass:[NSDictionary class]]) {
                        [stack addObject:temp];
                    } else if ([last isKindOfClass:[NSString class]] || [last isKindOfClass:[NSNumber class]]) {
                        obj = [[stack lastObject] retain];
                        [stack removeLastObject];
                        if (![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
                            if (e != NULL) {
                                *e = [self _constructErrorFromParser:NULL];
                            }
                            // An error occurred, set the stack to null and exit loop
                            done = TRUE;
                            stack = nil;
                        } else {
                            [[stack lastObject] setObject:temp forKey:obj];
                        }
                        [obj release];
                    }

                    [temp release];
                    break;
                case YAML_STREAM_END_EVENT:
                    done = YES;
                    break;
                case YAML_NO_EVENT:
                default:
                    break;
            }
        }
        yaml_event_delete(&event);
    }

    // we've reached the end of the stream, nothing additional to parse
    readyToParse = NO;
    return stack;
}

// TODO: oof, add tag support.

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
    NSString *stringValue = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
    NSString *tagString = (event.data.scalar.tag == NULL ? nil :
                           [NSString stringWithUTF8String:(const char *)event.data.scalar.tag]);

    // Special event, if scalar style is not a "plain" style then just return the string representation
    // Special event, if the tag is set to !!str then do not try to automatically resolve the type of data specified.
    if ([tagString isEqualToString:YKStringTagDeclaration] ||
        (tagString == nil && event.data.scalar.style != YAML_PLAIN_SCALAR_STYLE))
        return stringValue;

    // Special event, if the tag is set to !!null then just return null
    if ([tagString isEqualToString:YKNullTagDeclaration])
        return [NSNull null];

    if ([tagString isEqualToString:YKBinaryTagDeclaration])
        return [NSData dataFromBase64String:stringValue];

    // Try to automatically determine the type of data specified, if we cannot determine the data-type then just return
    // the stringValue
    NSArray *components = nil;
    id results = stringValue;

    // Determine if an 'Integer' was specified
    if ([(components = [stringValue arrayOfCaptureComponentsMatchedByRegex:YAML_INT_BINARY_REGEX]) count] != 0) {
        results = [NSNumber numberWithInt:
                   ([[[components objectAtIndex:0] objectAtIndex:1] isEqualToString:@"-"] ? -1 : 1) *
                   [[[components objectAtIndex:0] objectAtIndex:2] intValueFromBase:2]];
    } else if ([stringValue isMatchedByRegex:YAML_INT_OCTAL_REGEX]) {
        results = [NSNumber numberWithInt:[stringValue intValueFromBase:8]];
    } else if ([stringValue isMatchedByRegex:YAML_INT_DECIMAL_REGEX]) {
        results = [NSNumber numberWithInt:[stringValue intValueFromBase:10]];
    } else if ([stringValue isMatchedByRegex:YAML_INT_HEX_REGEX]) {
        results = [NSNumber numberWithInt:[stringValue intValueFromBase:16]];
    } else if ([stringValue isMatchedByRegex:YAML_INT_SEXAGESIMAL_REGEX]) {
        NSInteger resultValue = 0;
        for (NSString *component in [stringValue componentsSeparatedByString:@":"]) {
            resultValue = (resultValue * 60) + [component intValueFromBase:10];
        }
        results = [NSNumber numberWithInt:resultValue];
    // Determine if a 'Float' was specified
    } else if ([stringValue isMatchedByRegex:YAML_FLOAT_DECIMAL_REGEX]) {
        results = [NSDecimalNumber decimalNumberWithString:[stringValue stringByReplacingOccurrencesOfString:@"_"
                                                                                               withString:@""]];
    } else if ([stringValue isMatchedByRegex:YAML_FLOAT_SEXAGESIMAL_REGEX]) {
        double resultValue = 0;
        for (NSString *component in [[stringValue stringByReplacingOccurrencesOfString:@"_" withString:@""]
                                     componentsSeparatedByString:@":"]) {
            resultValue = (resultValue * 60.0f) + [component doubleValue];
        }
        results = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithDouble:resultValue] decimalValue]];
    } else if ([stringValue isMatchedByRegex:YAML_FLOAT_INFINITY_REGEX]) {
        if ([stringValue hasPrefix:@"-"])
            results = (id)kCFNumberPositiveInfinity;
        else
            results = (id)kCFNumberNegativeInfinity;
    } else if ([stringValue isMatchedByRegex:YAML_FLOAT_NAN_REGEX]) {
        results = [NSDecimalNumber notANumber];
    // Determine if a 'Boolean' was specified
    } else if ([stringValue isMatchedByRegex:YAML_BOOL_TRUE_REGEX]) {
        results = (id)kCFBooleanTrue;
    } else if ([stringValue isMatchedByRegex:YAML_BOOL_FALSE_REGEX]) {
        results = (id)kCFBooleanFalse;
    // Determine if a 'Null' was specified
    } else if ([stringValue isMatchedByRegex:YAML_NULL_REGEX]) {
        results = [NSNull null];
    // Determine if a 'Timestamp' was specified
    } else if ([stringValue isMatchedByRegex:YAML_TIMESTAMP_YMD_REGEX]) {
        results = [NSDate dateWithString:[stringValue stringByAppendingFormat:@" 00:00:00 +0000"]];
    } else if ([(components = [stringValue arrayOfCaptureComponentsMatchedByRegex:YAML_TIMESTAMP_YMDTZ_REGEX]) count]) {
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
        if (deltaFromGMTInSeconds != 0) {
            timeZone = [NSTimeZone timeZoneForSecondsFromGMT:deltaFromGMTInSeconds];
        } else {
            timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        }

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
        results = resultDate;
    }

    // If an explict tag to cast to was not specified, then return the automatically casted values
    if (!tagString)
        return results;

    // Try to cast results to an 'Integer'
    if ([tagString isEqualToString:YKIntegerTagDeclaration]) {
        if (results == [NSNull null])
            return [NSNumber numberWithInt:0];
        if (![results isKindOfClass:[NSNumber class]])
            return [NSNull null];
        if ([results objCType] == @encode(int))
            return results;
        return [NSNumber numberWithInt:[results intValue]];
    // Try to cast results to a 'Float'
    } else if ([tagString isEqualToString:YKFloatTagDeclaration]) {
        if (results == [NSNull null])
            return [NSNumber numberWithDouble:0.0];
        if (![results isKindOfClass:[NSNumber class]])
            return [NSNull null];
        if ([results objCType] == @encode(float) || [results objCType] == @encode(double)
            || [results objCType] == @encode(NSDecimal))
            return results;
        return [NSNumber numberWithDouble:[results doubleValue]];
    // Try to cast results to a 'Boolean'
    } else if ([tagString isEqualToString:YKBooleanTagDeclaration]) {
        if (results == [NSNull null])
            return (id)kCFBooleanFalse;
        if (![results isKindOfClass:[NSNumber class]])
            return [NSNull null];
        if ([results objCType] == @encode(BOOL))
            return results;
        return ([results doubleValue] > 0 ? (id)kCFBooleanTrue : (id)kCFBooleanFalse);
    }

    return [NSNull null];
}

- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p
{
    int code = 0;
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    if (p != NULL) {
        // actual parser error
        code = p->error;
        // get the string encoding.
        NSStringEncoding enc = 0;
        switch(p->encoding) {
            case YAML_UTF8_ENCODING:
                enc = NSUTF8StringEncoding;
                break;
            case YAML_UTF16LE_ENCODING:
                enc = NSUTF16LittleEndianStringEncoding;
                break;
            case YAML_UTF16BE_ENCODING:
                enc = NSUTF16BigEndianStringEncoding;
                break;
            default: break;
        }
        [data setObject:[NSNumber numberWithInt:enc] forKey:NSStringEncodingErrorKey];

        [data setObject:[NSString stringWithUTF8String:p->problem] forKey:YKProblemDescriptionKey];
        [data setObject:[NSNumber numberWithInt:p->problem_offset] forKey:YKProblemOffsetKey];
        [data setObject:[NSNumber numberWithInt:p->problem_value] forKey:YKProblemValueKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.line] forKey:YKProblemLineKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.index] forKey:YKProblemIndexKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.column] forKey:YKProblemColumnKey];

        [data setObject:[NSString stringWithUTF8String:p->context] forKey:YKErrorContextDescriptionKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.line] forKey:YKErrorContextLineKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.column] forKey:YKErrorContextColumnKey];
        [data setObject:[NSNumber numberWithInt:p->context_mark.index] forKey:YKErrorContextIndexKey];
    } else if (readyToParse) {
        [data setObject:NSLocalizedString(@"Internal assertion failed, possibly due to specially malformed input.", @"") forKey:NSLocalizedDescriptionKey];
    } else {
        [data setObject:NSLocalizedString(@"YAML parser was not ready to parse.", @"") forKey:NSLocalizedFailureReasonErrorKey];
        [data setObject:NSLocalizedString(@"Did you remember to call readFile: or readString:?", @"") forKey:NSLocalizedDescriptionKey];
    }

    return [NSError errorWithDomain:YKErrorDomain code:code userInfo:data];
}

- (void)_destroy
{
    stringInput = nil;
    if (fileInput) {
        fclose(fileInput);
        fileInput = NULL;
    }
    yaml_parser_delete(opaque_parser);
}

- (void)finalize
{
    [self _destroy];
    free(opaque_parser), opaque_parser = nil;
    [super finalize];
}

- (void)dealloc
{
    [self _destroy];
    free(opaque_parser), opaque_parser = nil;
    [super dealloc];
}

@end
