//
//  YKUnknownNode.h
//  YAMLKit
//
//  Created by Faustino Osuna on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
    NSUInteger line;
    NSUInteger column;
    NSUInteger index;
} YKMark;

typedef struct {
    YKMark start;
    YKMark end;
} YKRange;

YKRange YKMakeRange(YKMark start, YKMark end);
YKMark YKMakeMark(NSUInteger line, NSUInteger column, NSUInteger index);

@interface YKUnknownNode : NSObject {
    YKRange position;
    NSString *resolvedTag;
    NSString *castedTag;
    NSString *stringValue;
}

+ (id)unknownNodeWithStringValue:(NSString *)aStringValue resolvedTag:(NSString *)aResolvedTag
                       castedTag:(NSString *)aCastedTag position:(YKRange)aPosition;
- (id)initWithStringValue:(NSString *)aStringValue resolvedTag:(NSString *)aResolvedTag castedTag:(NSString *)aCastedTag
                 position:(YKRange)aPosition;

@property (readonly) YKRange position;
@property (readonly) NSString *resolvedTag;
@property (readonly) NSString *castedTag;
@property (readonly) NSString *stringValue;

@end
