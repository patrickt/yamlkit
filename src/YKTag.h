//
//  YKTag.h
//  YAMLKit
//
//  Created by Faustino Osuna on 9/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YKTag;

@protocol YKTagDelegate

- (id)tag:(YKTag *)tag decodeFromString:(NSString *)stringValue extraInfo:(NSDictionary *)extraInfo;
- (id)tag:(YKTag *)tag castValue:(id)value fromTag:(YKTag *)castingTag;
- (id)tag:(YKTag *)tag castValue:(id)value toTag:(YKTag *)castingTag;

@end

@interface YKTag : NSObject {
    NSString *verbatim;
    NSString *shorthand;
    id delegate;
}

- (id)initWithURI:(NSString *)aURI delegate:(id)aDelegate;
- (id)decodeFromString:(NSString *)stringValue explicitTag:(YKTag *)explicitTag;
- (id)castValue:(id)value fromTag:(YKTag *)castingTag;
- (id)castValue:(id)value toTag:(YKTag *)castingTag;

@property (readonly) NSString *verbatim;
@property (readonly) NSString *shorthand;
@property (assign) id delegate;

@end

@interface YKRegexTag : YKTag {
    NSDictionary *regexDeclarations;
}

- (void)addRegexDeclaration:(NSString *)regex hint:(id)hint;

@end
