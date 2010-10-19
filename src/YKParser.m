//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "yaml.h"
#import "YKParser.h"
#import "YKConstants.h"
#import "YKTag.h"
#import "YKNativeTagManager.h"

@interface YKParser (YKParserPrivateMethods)

- (id)_interpretObjectFromEvent:(yaml_event_t)event;
- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p;
- (void)_destroy;

@end

@implementation YKParser

@synthesize isReadyToParse=readyToParse;
@synthesize tagsByName;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    opaque_parser = malloc(sizeof(yaml_parser_t));
    if (!opaque_parser || !yaml_parser_initialize(opaque_parser))
    {
        [self release];
        return nil;
    }

    tagsByName = [[NSMutableDictionary alloc] initWithDictionary:[[YKNativeTagManager sharedManager] tagsByName]];

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

- (void)addTag:(YKTag *)tag
{
    [tagsByName setObject:tag forKey:[tag verbatim]];
}

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
    NSString *stringValue = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
    NSString *explicitTagString = (event.data.scalar.tag == NULL ? nil :
                                   [NSString stringWithUTF8String:(const char *)event.data.scalar.tag]);

    // Special event, if scalar style is not a "plain" style then just return the string representation
    if (explicitTagString == nil && event.data.scalar.style != YAML_PLAIN_SCALAR_STYLE)
        return stringValue;

    // If an explicit tag was identified, try to cast it from nil, nil means that the implicit tag (or source tag) has
    // not been identified yet
    YKTag *explicitTag = [tagsByName valueForKey:explicitTagString];
    id results = [explicitTag castValue:stringValue fromTag:nil];
    if (results)
        return results;

    for (YKTag *resultsTag in [tagsByName allValues]) {
        if ((results = [resultsTag decodeFromString:stringValue explicitTag:explicitTag]))
            return results;
    }

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
    [tagsByName release], tagsByName = nil;
    [self _destroy];
    free(opaque_parser), opaque_parser = nil;
    [super dealloc];
}

@end
