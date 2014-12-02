//
//  TestEmitting.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <XCTest/XCTest.h>
#import <YAMLKit/YAMLKit.h>

@interface TestEmitting : XCTestCase {
	YKEmitter *e;
}

- (void)testSimpleEmitting;
//- (void)testComplicatedEmitting;
- (void)testExplicitDelimitation;
//- (void)testLineBreakModification;
//- (void)testDifferentEncodings;
//- (void)testCanonicalOutput;
//- (void)testIndentation;
//- (void)testEscapingUnicodeCharacters;
//- (void)testLineWidthModification;

@end
