//
//  TestParsing.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <SenTestingKit/SenTestingKit.h>
#import <YAMLKit/YAMLKit.h>

@interface TestParsing : SenTestCase {
    YKParser *p;
}

- (void)testVerySimpleLoadingFromFile;
- (void)testModerateLoadingFromFile;
- (void)testWithNonexistentFile;
//- (void)testSuccessfulLoadingUsingErrors;
//- (void)testUnsuccessfulLoadingUsingErrors;
//- (void)testWhatHappensWhenParseIsCalledTwice;

- (void)testVerySimpleStringParsing;
- (void)testDigitPrefixedStringParsing;
- (void)testStringEncoding;
//- (void)testWithMalformedStringInput;

- (void)testExplicitStringCasting;
- (void)testAutomaticIntegerCasting;
- (void)testExplicitIntegerCasting;
- (void)testAutomaticFloatCasting;
- (void)testExplicitFloatCasting;
- (void)testAutomaticBooleanCasting;
- (void)testExplicitBooleanCasting;
- (void)testAutomaticNullCasting;
- (void)testExplicitNullCasting;
- (void)testAutomaticTimestampCasting;
- (void)testExplicitBinaryCasting;
//- (void)testWithCustomInputHandler;

@end
