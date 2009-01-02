//
//  YKParser.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Cocoa/Cocoa.h>
#import "yaml.h"

@interface YKParser : NSObject {
	BOOL castsNumericScalars;
    FILE* fileInput;
	const char *stringInput;
    yaml_parser_t parser;
    
    NSMutableArray *parsedObjects;
}

- (void)reset;
- (BOOL)readString:(NSString *)path;
- (BOOL)readFile:(NSString *)path;
- (NSArray *)parse;

@property(assign) BOOL castsNumericScalars;

@end
