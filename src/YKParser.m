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
        fileInput = fopen([aString fileSystemRepresentation], "r");
        if((!yaml_parser_initialize(&parser)) || (fileInput == NULL)) {
            [self release]; return nil;
        }
        yaml_parser_set_input_file(&parser, fileInput);
    }
    return self;
}

- (id)initWithString:(NSString *)aString
{
	if(self = [super init]) {
		memset(&parser, 0, sizeof(parser));
		stringInput = [aString UTF8String];
        if(!yaml_parser_initialize(&parser)) {
            [self release]; return nil;
        };
		yaml_parser_set_input_string(&parser, (const unsigned char *)stringInput, [aString length]);
	}
	return self;
}

- (NSArray *)parse
{
    yaml_event_t event;
    int done = 0;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];
    
    while(!done) {
        if(!yaml_parser_parse(&parser, &event)) {
			break;
		}
        done = (event.type == YAML_STREAM_END_EVENT);
        switch(event.type) {
            case YAML_SCALAR_EVENT:
                obj = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
				// TODO: Put in some code here to make educated guesses as to whether
				// the scalars are strings or numeric literals (by querying event.data.scalar.style).
                temp = [stack lastObject];
                
                if([temp isKindOfClass:[NSArray class]]) {
                    [temp addObject:obj];
                } else if([temp isKindOfClass:[NSDictionary class]]) {
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
				// TODO: Check for retain count errors.
                temp = [stack lastObject];
                [stack removeLastObject];
		                
                id last = [stack lastObject];
				if(last == nil) {
					[stack addObject:temp];
					break;
				} else if([last isKindOfClass:[NSArray class]]) {
                    [last addObject:temp];
                } else if ([last isKindOfClass:[NSDictionary class]]) {
                    [stack addObject:temp];
                } else if ([last isKindOfClass:[NSString class]]) {
                    obj = [[stack lastObject] retain];
                    [stack removeLastObject];
                    NSAssert([[stack lastObject] isKindOfClass:[NSDictionary class]], 
                        @"last object in stack was not a dictionary!");
                    [[stack lastObject] setObject:temp forKey:obj];
                }
                break;
            case YAML_NO_EVENT:
                NSLog(@"ERROR: no event found!");
                break;
            default:
                break;
        }
        yaml_event_delete(&event);
    }
    return stack;
}

- (void)finalize
{
	yaml_parser_delete(&parser);
	if(fileInput != NULL) fclose(fileInput);
	[super finalize];
}

- (void)dealloc
{
	yaml_parser_delete(&parser);
	if(fileInput != NULL) fclose(fileInput);
    [super dealloc];
}

@end
