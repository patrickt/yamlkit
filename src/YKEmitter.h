//
//  YKEncoder.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Cocoa/Cocoa.h>
#import "yaml.h"

@interface YKEmitter : NSObject {
    yaml_emitter_t emitter;
    yaml_document_t document;
    FILE *output;
    NSMutableData *buffer;
}

- (id)initWithFile:(NSString *)string;
- (id)initWithCapacity:(int)bSize;
- (NSString *)emittedString;
- (void)emitItem:(id)item;
- (int)writeItem:(id)item toDocument:(yaml_document_t *)document;

@end
