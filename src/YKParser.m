//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKParser.h"
#import "YKConstants.h"

static BOOL _isBooleanTrue(NSString *aString);
static BOOL _isBooleanFalse(NSString *aString);

@interface YKParser (YKParserPrivateMethods)

- (id)_interpretObjectFromEvent:(yaml_event_t)event;
- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p;

@end

@implementation YKParser

@synthesize isReadyToParse=readyToParse;

- (void)reset
{
    stringInput = nil;

    if (fileInput) {
        fclose(fileInput);
        fileInput = NULL;
    }
    yaml_parser_delete(&parser);
    memset(&parser, 0, sizeof(parser));
}

- (BOOL)readFile:(NSString *)path
{
    if (!path || [path isEqualToString:@""])
        return FALSE;

    [self reset];
    fileInput = fopen([path fileSystemRepresentation], "r");
    readyToParse = ((fileInput != NULL) && (yaml_parser_initialize(&parser)));
    if (readyToParse)
        yaml_parser_set_input_file(&parser, fileInput);
    return readyToParse;
}

- (BOOL)readString:(NSString *)str
{
    if (!str || [str isEqualToString:@""])
        return FALSE;

    [self reset];
    stringInput = [str UTF8String];
    readyToParse = yaml_parser_initialize(&parser);
    if (readyToParse)
        yaml_parser_set_input_string(&parser, (const unsigned char *)stringInput, [str length]);
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
        if (!yaml_parser_parse(&parser, &event)) {
            if (e != NULL) {
                *e = [self _constructErrorFromParser:&parser];
            }
            // An error occurred, set the stack to null and exit loop
            stack = nil;
            done = TRUE;
        } else {
            done = (event.type == YAML_STREAM_END_EVENT);
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
                        }
                        [[stack lastObject] setObject:temp forKey:obj];
                        [obj release];
                    }
                    [temp release];
                    break;
                case YAML_NO_EVENT:
                    break;
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

typedef union {
    int int_value;
    double double_value;
    unsigned long long hex_value;
    NSDecimal decimal_value;
} scalar_value_t;

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
    NSString *stringValue = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
    if (event.data.scalar.style != YAML_PLAIN_SCALAR_STYLE)
        return stringValue;

    scalar_value_t scalar_value;
    NSScanner *scanner = [NSScanner scannerWithString:stringValue];

    if ([stringValue hasPrefix:@"0x"] || [stringValue hasPrefix:@"0X"]) {
        [scanner setScanLocation:2];
        if ([scanner scanHexLongLong:&scalar_value.hex_value] && [scanner isAtEnd]) {
            return [NSNumber numberWithUnsignedLongLong:scalar_value.hex_value];
        }
    } else if ([stringValue hasPrefix:@"0"]) {
        [scanner setScanLocation:1];
        if ([scanner scanInt:NULL] && [scanner isAtEnd]) {
            scalar_value.int_value = 0;
            sscanf((const char *)(event.data.scalar.value+1), "%o", &scalar_value.int_value);
            return [NSNumber numberWithInt:scalar_value.int_value];
        }
    }
    [scanner setScanLocation:0];

    // Integers are automatically casted unless given a !!str tag.
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[\\-+]?\\d{1,3}(\\,\\d{3})*(\\.\\d+)?"] evaluateWithObject:stringValue]) {
        stringValue = [[stringValue stringByReplacingOccurrencesOfString:@"," withString:@""]
                       stringByReplacingOccurrencesOfString:@"+" withString:@""];
        scanner = [NSScanner scannerWithString:stringValue];
    }

    if ([scanner scanInt:&scalar_value.int_value] && [scanner isAtEnd]) {
        return [NSNumber numberWithInt:scalar_value.int_value];
    }
    [scanner setScanLocation:0];

    if ([scanner scanDecimal:&scalar_value.decimal_value] && [scanner isAtEnd]) {
        return [NSDecimalNumber decimalNumberWithDecimal:scalar_value.decimal_value];
    }
    [scanner setScanLocation:0];

    if ([scanner scanDouble:&scalar_value.double_value] && [scanner isAtEnd]) {
        return [NSNumber numberWithDouble:scalar_value.double_value];
    }

    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-6]?[0-9]((\\:[0-5][0-9])|(\\:60))*"] evaluateWithObject:stringValue]) {
        int sexagesimalValue = 0;
        NSArray *components = [stringValue componentsSeparatedByString:@":"];
        for (NSString *component in components) {
            sexagesimalValue *= 60;
            sexagesimalValue += [component intValue];
        }
        return [NSNumber numberWithInt:sexagesimalValue];
    // FIXME: Boolean parsing here is not in accordance with the YAML standards.
    }

    if (_isBooleanTrue(stringValue))     {
        return [NSNumber numberWithBool:YES];
    }

    if (_isBooleanFalse(stringValue))    {
        return [NSNumber numberWithBool:NO];
    }

    if ([stringValue isEqualToString:@"~"]) {
        return [NSNull null];
    }
    // TODO: add date parsing.

    return stringValue;
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

- (void)finalize
{
    [self reset];
    [super finalize];
}

- (void)dealloc
{
    [self reset];
    [super dealloc];
}

@end

static BOOL _isBooleanFalse(NSString *aString)
{
    const char *cstr = [aString UTF8String];
    char *falseValues[] = {
        "false", "False", "FALSE",
        "n", "N", "NO", "No", "no",
        "off", "Off", "OFF"
    };
    size_t length = sizeof(falseValues) / sizeof(*falseValues);
    int index;
    for (index = 0; index < length; index++) {
        if (strcmp(cstr, falseValues[index]) == 0)
            return TRUE;
    }
    return FALSE;
}

static BOOL _isBooleanTrue(NSString *aString)
{
    const char *cstr = [aString UTF8String];
    char *trueValues[] = {
        "true", "TRUE", "True",
        "y", "Y", "Yes", "yes", "YES",
        "on", "On", "ON"
    };
    size_t length = sizeof(trueValues) / sizeof(*trueValues);
    int index;
    for (index = 0; index < length; index++) {
        if (strcmp(cstr, trueValues[index]) == 0)
            return TRUE;
    }
    return FALSE;
}
