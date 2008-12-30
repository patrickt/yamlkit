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
}

- (id)initWithFile:(NSString *)aString;

@end
