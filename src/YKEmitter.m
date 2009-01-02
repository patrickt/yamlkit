//
//  YKEmitter.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKEmitter.h"

@implementation YKEmitter


@synthesize usesExplicitDelimiters;

- (id)init
{
    if(self = [super init]) {
        memset(&emitter, 0, sizeof(emitter));
        yaml_emitter_initialize(&emitter);
        
        buffer = [NSMutableData data];
        // I am overjoyed that this works.
        // Coincidentally, the order of arguments to CFDataAppendBytes are just right
        // such that if I pass the buffer as the data parameter, I can just use 
        // a pointer to CFDataAppendBytes to tell the emitter to write to the NSMutableData.
        yaml_emitter_set_output(&emitter, CFDataAppendBytes, buffer);
        [self setUsesExplicitDelimiters:NO];
    }
	return self;
}

- (void)emitItem:(id)item
{
    // Create and initialize a document to hold this.
    yaml_document_t document;
    memset(&document, 0, sizeof(document));
    yaml_document_initialize(&document, NULL, NULL, NULL, !usesExplicitDelimiters, !usesExplicitDelimiters);
    
    [self _writeItem:item toDocument:&document];
    yaml_emitter_dump(&emitter, &document);
    yaml_document_delete(&document);
}

- (int)_writeItem:(id)item toDocument:(yaml_document_t *)doc;
{
	int nodeID = 0;
	if([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSSet class]]) {
		// emit beginning sequence
		nodeID = yaml_document_add_sequence(doc, (yaml_char_t *)YAML_DEFAULT_SEQUENCE_TAG, YAML_ANY_SEQUENCE_STYLE);
		for(id subitem in item) {
			int newItem = [self _writeItem:subitem toDocument:doc];
			yaml_document_append_sequence_item(doc, nodeID, newItem);
		}
	} else if([item isKindOfClass:[NSDictionary class]]) {
		// emit beginning mapping
		nodeID = yaml_document_add_mapping(doc, (yaml_char_t *)YAML_DEFAULT_MAPPING_TAG, YAML_ANY_MAPPING_STYLE);
		for(id key in item) {
			int keyID = [self _writeItem:key toDocument:doc];
			int valueID = [self _writeItem:[item objectForKey:key] toDocument:doc];
			yaml_document_append_mapping_pair(doc, nodeID, keyID, valueID);
		}
	} else {
		// TODO: Add optional support for tagging emitted items.
		nodeID = yaml_document_add_scalar(doc, (yaml_char_t *)YAML_DEFAULT_SCALAR_TAG, (yaml_char_t*)[[item description] UTF8String], strlen([[item description] UTF8String]), YAML_ANY_SCALAR_STYLE);
	}
	return nodeID;
}

- (NSString *)emittedString
{
    return [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];
}

- (NSData *)emittedData
{
	return [NSData dataWithData:buffer];
}

@end
