//
//  YKEncoder.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Foundation/Foundation.h>

@interface YKEmitter : NSObject {
    NSMutableData *buffer;
    BOOL usesExplicitDelimiters;
    NSStringEncoding encoding;
    void *opaque_emitter;
}

- (void)emitItem:(id)item;
- (NSString *)emittedString;
- (NSData *)emittedData;

@property (assign) BOOL usesExplicitDelimiters;
@property (assign) NSStringEncoding encoding;

@end
