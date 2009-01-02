//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKParser.h"

@implementation YKParser

@synthesize castsNumericScalars;

- (id)init
{
    if(self = [super init]) {
        parsedObjects = nil;
        [self setCastsNumericScalars:YES];
    }
	return self;
}

- (void)reset
{
    if(fileInput) {
        fclose(fileInput);
    }
	yaml_parser_delete(&parser);
    memset(&parser, 0, sizeof(parser));
    parsedObjects = nil;
}

- (BOOL)readFile:(NSString *)path
{
    [self reset];
    fileInput = fopen([path fileSystemRepresentation], "r");
    BOOL succeeded = ((fileInput != NULL) && (yaml_parser_initialize(&parser)));
    if(succeeded) yaml_parser_set_input_file(&parser, fileInput);
    return succeeded;
}

- (BOOL)readString:(NSString *)str
{
    [self reset];
    stringInput = [str UTF8String];
    BOOL succeeded = yaml_parser_initialize(&parser);
    if(succeeded) yaml_parser_set_input_string(&parser, (const unsigned char *)stringInput, [str length]);
    return succeeded;
}

- (NSArray *)parse
{
    yaml_event_t event;
    int done = 0;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];
    
    while(!done) {
        if(!yaml_parser_parse(&parser, &event)) {
            return nil;
		}
        done = (event.type == YAML_STREAM_END_EVENT);
        switch(event.type) {
            case YAML_SCALAR_EVENT:
                obj = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
				
				if((event.data.scalar.style == YAML_PLAIN_SCALAR_STYLE) && [self castsNumericScalars]) {
					NSScanner *scanner = [NSScanner scannerWithString:obj];
					if([scanner scanInt:NULL]) {
						obj = [NSNumber numberWithInt:[obj intValue]];
					}
					// TODO: Check for doubles, null (~), true/false
				}
                temp = [stack lastObject];
                
                if([temp isKindOfClass:[NSArray class]]) {
                    [temp addObject:obj];
                } else if([temp isKindOfClass:[NSDictionary class]]) {
                    [stack addObject:obj];
                } else if([temp isKindOfClass:[NSString class]] || [temp isKindOfClass:[NSValue class]])  {
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
                } else if ([last isKindOfClass:[NSString class]] || [last isKindOfClass:[NSNumber class]]) {
                    obj = [[stack lastObject] retain];
                    [stack removeLastObject];
                    NSAssert([[stack lastObject] isKindOfClass:[NSDictionary class]], 
                        @"last object in stack was not a dictionary!");
                    [[stack lastObject] setObject:temp forKey:obj];
                }
                break;
            case YAML_NO_EVENT:
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
