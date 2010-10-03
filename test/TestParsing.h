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
- (void)testVerySimpleStringParsing;
- (void)testDigitPrefixedStringParsing;
- (void)testModerateLoadingFromFile;
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
- (void)testWithNonexistentFile;
//- (void)testWithMalformedStringInput;
//- (void)testSuccessfulLoadingUsingErrors;
//- (void)testUnsuccessfulLoadingUsingErrors;
//- (void)testWhatHappensWhenParseIsCalledTwice;
- (void)testStringEncoding;
//- (void)testWithCustomInputHandler;

@end
