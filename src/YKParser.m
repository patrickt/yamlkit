//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKParser.h"


@implementation YKParser

- (id)initWithFile:(NSString *)aString
{
    if(self = [super init]) {
        memset(&parser, 0, sizeof(parser));
        yaml_parser_initialize(&parser);
        fileInput = fopen([aString UTF8String], "r");
    }
    return self;
}

- (id)parse
{
    yaml_event_t event;
    int done = 0;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];
    
    while(!done) {
        yaml_parser_parse(&parser, &event);
        done = (event.type == YAML_STREAM_END_EVENT);
        
        switch(event.type) {
            case YAML_SCALAR_EVENT:
                obj = [NSString stringWithUTF8String:(char *)event.data.scalar.value];
                temp = [stack lastObject];
                
                if([temp isKindOfClass:[NSMutableArray class]]) {
                    [temp addObject:obj];
                } else if([temp isKindOfClass:[NSMutableDictionary class]]) {
                    [stack addObject:obj];
                } else if([temp isKindOfClass:[NSString class]]) {
                    [temp retain];
                    [stack removeLastObject];
                    NSAssert([[stack lastObject] isKindOfClass:[NSMutableDictionary class]], 
                        @"last object in stack was not a dictionary!");
                    [[stack lastObject] setObject:obj forKey:temp];
                    [temp release];
                } else {
                    
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
                if([last isKindOfClass:[NSMutableArray class]]) {
                    [last addObject:temp];
                } else if ([last isKindOfClass:[NSMutableDictionary class]]) {
                    [stack addObject:temp];
                } else if ([last isKindOfClass:[NSString class]]) {
                    obj = [[stack lastObject] retain];
                    [stack removeLastObject];
                    NSAssert([[stack lastObject] isKindOfClass:[NSMutableDictionary class]], 
                        @"last object in stack was not a dictionary!");
                    [[stack lastObject] setObject:temp forKey:obj];
                }
                [temp release];
                temp = nil;
                break;
            case YAML_NO_EVENT:
                NSLog(@"ERROR: no event found!");
                break;
            default:
                NSLog(@"Warning: no event caught!");
                break;
        }
        yaml_event_delete(&event);
    }
    return [[stack lastObject] lastObject];
}

- (void)dealloc
{
    yaml_parser_delete(&parser);
    fclose(fileInput);
    [super dealloc];
}

@end
