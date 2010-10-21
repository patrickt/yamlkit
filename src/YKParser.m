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

    NSMutableArray *documents = [NSMutableArray array];
    NSMutableArray *containerStack = [NSMutableArray array];
    BOOL startNewDocument = FALSE;
    id node;

    while (!done) {
        if (!yaml_parser_parse(opaque_parser, &event)) {
            if (e != NULL) {
                *e = [self _constructErrorFromParser:opaque_parser];
            }
            // An error occurred, set the stack to null and exit loop
            documents = nil;
            done = TRUE;
        } else {
            switch (event.type) {
                case YAML_STREAM_START_EVENT:
                    node = nil;
                    break;
                case YAML_STREAM_END_EVENT:
                    node = nil;
                    done = TRUE;
                    break;
                case YAML_DOCUMENT_START_EVENT:
                    startNewDocument = TRUE;
                    node = nil;
                    [containerStack removeAllObjects];
                    break;
                case YAML_DOCUMENT_END_EVENT:
                    break;
                case YAML_MAPPING_START_EVENT:
                    node = [NSMutableDictionary dictionary];
                    break;
                case YAML_MAPPING_END_EVENT:
                    [containerStack removeLastObject];
                    node = nil;
                    break;
                case YAML_SEQUENCE_START_EVENT:
                    node = [NSMutableArray array];
                    break;
                case YAML_SEQUENCE_END_EVENT:
                    [containerStack removeLastObject];
                    node = nil;
                    break;
                case YAML_SCALAR_EVENT:
                    if ([[containerStack lastObject] isKindOfClass:[NSDictionary class]])
                        node = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
                    else
                        node = [self _interpretObjectFromEvent:event];
                    break;
                case YAML_NO_EVENT:
                default:
                    break;
            }
            if (node) {
                if ([[containerStack lastObject] isKindOfClass:[NSString class]]) {
                    NSString *key = [[containerStack lastObject] retain];
                    [containerStack removeLastObject];
                    [[containerStack lastObject] setValue:node forKey:key];
                    [key release];
                } else if ([[containerStack lastObject] isKindOfClass:[NSDictionary class]]) {
                    [containerStack addObject:node];
                } else if ([[containerStack lastObject] isKindOfClass:[NSArray class]]) {
                    [[containerStack lastObject] addObject:node];
                } else if (startNewDocument) {
                    [documents addObject:node];
                    startNewDocument = FALSE;
                }
                if ([node isKindOfClass:[NSDictionary class]] || [node isKindOfClass:[NSArray class]]) {
                    [containerStack addObject:node];
                }
            }
        }
        yaml_event_delete(&event);
    }

    // we've reached the end of the stream, nothing additional to parse
    readyToParse = NO;
    return documents;
}

- (void)addTag:(YKTag *)tag
{
    [tagsByName setObject:tag forKey:[tag verbatim]];
}

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
    NSString *stringValue = (!event.data.scalar.value ? nil :
                             [NSString stringWithUTF8String:(const char *)event.data.scalar.value]);
    NSString *explicitTagString = (!event.data.scalar.tag ? nil :
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

        [data setObject:(!p->problem ? [NSNull null] : [NSString stringWithUTF8String:p->problem])
                 forKey:YKProblemDescriptionKey];
        [data setObject:[NSNumber numberWithInt:p->problem_offset] forKey:YKProblemOffsetKey];
        [data setObject:[NSNumber numberWithInt:p->problem_value] forKey:YKProblemValueKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.line] forKey:YKProblemLineKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.index] forKey:YKProblemIndexKey];
        [data setObject:[NSNumber numberWithInt:p->problem_mark.column] forKey:YKProblemColumnKey];

        [data setObject:(!p->context ? [NSNull null] : [NSString stringWithUTF8String:p->context])
                 forKey:YKErrorContextDescriptionKey];
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
