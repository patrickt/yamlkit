//
//  TestParsing.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestParsing.h"

@implementation TestParsing

- (void)setUp
{
    p = [[[YKParser alloc] init] autorelease];
}

- (void)testVerySimpleLoadingFromFile
{
    [p readFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"verysimple" ofType:@"yaml"]];
    id o = [p parse];
    STAssertNotNil(o, @"#parse method failed to return anything.");
    NSArray *needed = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Escape of the Unicorn" forKey:@"title"]];
    STAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testVerySimpleStringParsing
{
    [p readString:@"- foo\n- bar\n- baz"];
    id o = [p parse];
    STAssertNotNil(o, @"#parse method failed to return anything.");
    NSArray *needed = [NSArray arrayWithObject: [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil]];
    STAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testDigitPrefixedStringParsing
{
    [p readString:@"- 325de3fa"];
    id o = [p parse];
    STAssertNotNil(o, @"#parse method failed to return anything.");
    NSArray *needed = [NSArray arrayWithObject: [NSArray arrayWithObjects:@"325de3fa", nil]];
    STAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testModerateLoadingFromFile
{
    [p readFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"moderate" ofType:@"yaml"]];
    NSArray *o = [p parse];
    STAssertNotNil(o, @"#parse method failed to return anything.");
    NSDictionary *first = [o objectAtIndex:0];
    STAssertEqualObjects([first objectForKey:@"receipt"], @"Oz-Ware Purchase Invoice", @"recieved incorrect data from loaded YAML");
    STAssertTrue(([[first objectForKey:@"specialDelivery"] length] > 25), @"did not parse a multiline string correctly");
}

- (void)testAutomaticIntegerCasting
{
    [p readString:@"- 685230\n- +685_230\n- 02472256\n- 0x_0A_74_AE\n- 0b1010_0111_0100_1010_1110\n- 190:20:30\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:685230], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticFloatCasting
{
    [p readString:@"- 6.8523015e+5\n- 685.230_15e+03\n- 685_230.15\n- 190:20:30.15\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:685230.15], @"incorrectly cast to NSDecimalNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticBooleanCasting
{
    [p readString:@"- true\n- True\n- TRUE\n- y\n- Y\n- Yes\n- YES\n- yes\n- on\n- On\n- ON\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            STAssertTrue([value boolValue], @"boolean value was not true");
        } else {
            STFail(@"'%@' was not a boolean it was %@ (%d -> %d)", value, NSStringFromClass(value), CFGetTypeID(value), CFBooleanGetTypeID());
        }
    }
    [p readString:@"- false\n- False\n- FALSE\n- n\n- N\n- No\n- NO\n- off\n- Off\n- OFF\n"];
    o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            STAssertFalse([value boolValue], @"boolean value was not false");
        } else {
            STFail(@"'%@' was not a boolean it was %@ (%d -> %d)", value, NSStringFromClass(value), CFGetTypeID(value), CFBooleanGetTypeID());
        }
    }
}

- (void)testAutomaticNullCasting
{
    [p readString:@"- null\n- Null\n- NULL\n- ~\n- \n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertEqualObjects(value, [NSNull null], @"incorrectly cast to NSNull <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticTimestampCasting
{
    [p readString:@"- 2001-12-14t21:59:43.10-05:00\n- 2001-12-14 21:59:43.10 -5\n"];
    NSDate *date = [[NSDate dateWithString:@"2001-12-14 23:29:43 +0100"] dateByAddingTimeInterval:0.1];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }

    [p readString:@"- 2001-12-15T02:59:43.1Z\n- 2001-12-15 2:59:43.10\n"];
    date = [[NSDate dateWithString:@"2001-12-15 03:59:43 +0100"] dateByAddingTimeInterval:0.1];
    o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }

    [p readString:@"- 2001-12-14\n"];
    date = [NSDate dateWithString:@"2001-12-14 01:00:00 +0100"];
    o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testWithNonexistentFile
{
    STAssertFalse([p readFile:@"test/doesnotexist"], @"#readFile returned true when given a nonexistent file");
    STAssertFalse([p isReadyToParse], @"returned a false value for #readyToParse");
    NSError *e;
    NSArray *o = [p parseWithError:&e];
    STAssertNil(o, @"did not return nil when everything went wrong.");
    STAssertEqualObjects([e domain], @"YKErrorDomain", @"returned a different error domain");
}

@end
