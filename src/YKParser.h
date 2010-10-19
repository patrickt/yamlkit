//
//  YKParser.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Foundation/Foundation.h>
#import <YAMLKit/YKTag.h>

@interface YKParser : NSObject {
    BOOL readyToParse;
    FILE *fileInput;
    const char *stringInput;
    void *opaque_parser;
    NSMutableDictionary *tagsByName;
}

- (void)reset;
- (BOOL)readString:(NSString *)path;
- (BOOL)readFile:(NSString *)path;
- (NSArray *)parse;
- (NSArray *)parseWithError:(NSError **)e;

- (void)addTag:(YKTag *)tag;

@property (readonly) BOOL isReadyToParse;
@property (readonly) NSDictionary *tagsByName;

@end

