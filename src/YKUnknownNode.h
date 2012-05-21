//
//  YKUnknownNode.h
//  YAMLKit
//
//  Created by Faustino Osuna on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <YAMLKit/YKTag.h>

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
    YKTag *implicitTag;
    YKTag *explicitTag;
    NSString *stringValue;
}

+ (id)unknownNodeWithStringValue:(NSString *)aStringValue implicitTag:(YKTag *)aImplicitTag
                       explicitTag:(YKTag *)aExplicitTag position:(YKRange)aPosition;
- (id)initWithStringValue:(NSString *)aStringValue implicitTag:(YKTag *)aImplicitTag explicitTag:(YKTag *)aExplicitTag
                 position:(YKRange)aPosition;

@property (readonly) YKRange position;
@property (readonly) YKTag *implicitTag;
@property (readonly) YKTag *explicitTag;
@property (readonly) NSString *stringValue;

@end
