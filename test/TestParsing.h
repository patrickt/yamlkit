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
- (void)testAutomaticFloatCasting;
- (void)testAutomaticFloatCasting;
- (void)testAutomaticBooleanCasting;
- (void)testAutomaticNullCasting;
- (void)testExplicitNullCasting;
- (void)testAutomaticTimestampCasting;
- (void)testWithNonexistentFile;
//- (void)testWithMalformedStringInput;
//- (void)testSuccessfulLoadingUsingErrors;
//- (void)testUnsuccessfulLoadingUsingErrors;
//- (void)testWhatHappensWhenParseIsCalledTwice;
//- (void)testDifferentEncodings;
//- (void)testWithCustomInputHandler;

@end
