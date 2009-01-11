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
    NSMutableData *buffer;
	BOOL usesExplicitDelimiters;
	NSStringEncoding encoding;
}

- (void)emitItem:(id)item;
- (int)_writeItem:(id)item toDocument:(yaml_document_t *)document;
- (NSString *)emittedString;
- (NSData *)emittedData;

@property(assign) BOOL usesExplicitDelimiters;
@property(assign) NSStringEncoding encoding;

@end
