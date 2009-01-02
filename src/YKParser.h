//
//  YKParser.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Cocoa/Cocoa.h>
#import "yaml.h"

@interface YKParser : NSObject {
    yaml_parser_t parser;
    FILE* fileInput;
	const char *stringInput;
	BOOL castsNumericScalars;
}

- (id)initWithFile:(NSString *)path;
- (id)initWithString:(NSString *)aString;
- (NSArray *)parse;

@property(assign) BOOL castsNumericScalars;

@end
