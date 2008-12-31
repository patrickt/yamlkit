//
//  TestEmitting.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <SenTestingKit/SenTestingKit.h>


@interface TestEmitting : SenTestCase {

}

- (void)testSimpleEmitting;
- (void)testComplicatedEmitting;
- (void)testLineBreakModification;
- (void)testDifferentEncodings;
- (void)testCanonicalOutput;
- (void)testIndentation;
- (void)testEscapingUnicodeCharacters;
- (void)testLineWidthModification;

@end
