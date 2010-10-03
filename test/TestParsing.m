//
//  TestParsing.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestParsing.h"
#import "YKConstants.h"

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

- (void)testStringEncoding
{
    [p readFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ascii" ofType:@"yaml"]];
    NSArray *o = [p parse];
    STAssertTrue([@"Example" isEqualToString:[[o objectAtIndex:0] objectAtIndex:0]], @"string should be \"Example\" but was %@", [[o objectAtIndex:0] objectAtIndex:0]);

    [p readFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"utf16le" ofType:@"yaml"]];
    o = [p parse];
    STAssertTrue([@"Example" isEqualToString:[[o objectAtIndex:0] objectAtIndex:0]], @"string should be \"Example\" but was %@", [[o objectAtIndex:0] objectAtIndex:0]);

    [p readFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"utf16be" ofType:@"yaml"]];
    o = [p parse];
    STAssertTrue([@"Example" isEqualToString:[[o objectAtIndex:0] objectAtIndex:0]], @"string should be \"Example\" but was %@", [[o objectAtIndex:0] objectAtIndex:0]);
}

- (void)testExplicitStringCasting
{
    [p readString:@"- !!str 685230\n- !<tag:yaml.org,2002:str> 685230\n"];
    id o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSString class]], @"was not a string");
        STAssertEqualObjects(value, @"685230", @"incorrectly cast to NSString <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticIntegerCasting
{
    [p readString:@"- 685230\n- +685_230\n- 02472256\n- 0x_0A_74_AE\n- 0b1010_0111_0100_1010_1110\n- 190:20:30\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:685230], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testExplicitIntegerCasting
{
    [p readString:@"- !!int 6.8523015e+5\n- !!int 685.230_15e+03\n- !!int 685_230.15\n- !!int 190:20:30.15\n" \
     "- !<tag:yaml.org,2002:int> 6.8523015e+5\n- !<tag:yaml.org,2002:int> 685.230_15e+03\n" \
     "- !<tag:yaml.org,2002:int> 685_230.15\n- !<tag:yaml.org,2002:int> 190:20:30.15\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:685230], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!int true\n- !!int True\n- !!int TRUE\n- !!int y\n- !!int Y\n- !!int Yes\n" \
     "- !!int YES\n- !!int yes\n- !!int on\n- !!int On\n- !!int ON\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:1.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!int false\n- !!int False\n- !!int FALSE\n- !!int n\n- !!int N\n- !!int No\n" \
     "- !!int NO\n- !!int off\n- !!int Off\n- !!int OFF\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:0.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!int null\n- !!int Null\n- !!int NULL\n- !!int ~\n- !!int \n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithInt:0.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!int 2001-12-14t21:59:43.10-05:00\n- !!int 2001-12-14 21:59:43.10 -5\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[YKUnknownNode class]], @"was not unknown");
        STAssertEqualObjects([value castedTag], YKIntegerTagDeclaration, @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticFloatCasting
{
    [p readString:@"- 6.8523015e+5\n- 685.230_15e+03\n- 685_230.15\n- 190:20:30.15\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:685230.15], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testExplicitFloatCasting
{
    [p readString:@"- !!float 685230\n- !!float +685_230\n- !!float 02472256\n- !!float 0x_0A_74_AE\n" \
     "- !!float 0b1010_0111_0100_1010_1110\n- !!float 190:20:30\n- !<tag:yaml.org,2002:float> 685230\n" \
     "- !<tag:yaml.org,2002:float> +685_230\n- !<tag:yaml.org,2002:float> 02472256\n" \
     "- !<tag:yaml.org,2002:float> 0x_0A_74_AE\n- !<tag:yaml.org,2002:float> 0b1010_0111_0100_1010_1110\n" \
     "- !<tag:yaml.org,2002:float> 190:20:30\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:685230.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!float true\n- !!float True\n- !!float TRUE\n- !!float y\n- !!float Y\n- !!float Yes\n" \
     "- !!float YES\n- !!float yes\n- !!float on\n- !!float On\n- !!float ON\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:1.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!float false\n- !!float False\n- !!float FALSE\n- !!float n\n- !!float N\n- !!float No\n" \
     "- !!float NO\n- !!float off\n- !!float Off\n- !!float OFF\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:0.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!float null\n- !!float Null\n- !!float NULL\n- !!float ~\n- !!float \n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[NSNumber class]], @"was not a number");
        STAssertEqualObjects(value, [NSNumber numberWithDouble:0.0], @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!float 2001-12-14t21:59:43.10-05:00\n- !!float 2001-12-14 21:59:43.10 -5\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[YKUnknownNode class]], @"was not unknown");
        STAssertEqualObjects([value castedTag], YKFloatTagDeclaration, @"incorrectly cast to NSNumber <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticBooleanCasting
{
    [p readString:@"- true\n- True\n- TRUE\n- y\n- Y\n- Yes\n- YES\n- yes\n- on\n- On\n- ON\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            STAssertTrue([value boolValue], @"boolean value was not true");
        } else {
            STFail(@"'%@' was not a boolean it was %@ (%d -> %d)", value, NSStringFromClass(value), CFGetTypeID(value), CFBooleanGetTypeID());
        }
    }
    [p readString:@"- false\n- False\n- FALSE\n- n\n- N\n- No\n- NO\n- off\n- Off\n- OFF\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
            STAssertFalse([value boolValue], @"boolean value was not false");
        } else {
            STFail(@"'%@' was not a boolean it was %@ (%d -> %d)", value, NSStringFromClass(value), CFGetTypeID(value), CFBooleanGetTypeID());
        }
    }
}

- (void)testExplicitBooleanCasting {
    [p readString:@"- !!bool 685230\n- !!bool +685_230\n- !!bool 02472256\n- !!bool 0x_0A_74_AE\n" \
     "- !!bool 0b1010_0111_0100_1010_1110\n- !!bool 190:20:30\n- !!bool 6.8523015e+5\n- !!bool 685.230_15e+03\n" \
     "- !!bool 685_230.15\n- !!bool 190:20:30.15\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue(CFGetTypeID(value) == CFBooleanGetTypeID(), @"was not a boolean");
        STAssertEqualObjects(value, (id)kCFBooleanTrue, @"incorrectly cast to kCFBooleanTrue <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!bool null\n- !!bool Null\n- !!bool NULL\n- !!bool ~\n- !!bool \n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue(CFGetTypeID(value) == CFBooleanGetTypeID(), @"was not a boolean");
        STAssertEqualObjects(value, (id)kCFBooleanFalse, @"incorrectly cast to kCFBooleanFalse <%@(%@)>", NSStringFromClass([value class]), value);
    }
    [p readString:@"- !!bool 2001-12-14t21:59:43.10-05:00\n- !!bool 2001-12-14 21:59:43.10 -5\n"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertTrue([value isKindOfClass:[YKUnknownNode class]], @"was not unknown");
        STAssertEqualObjects([value castedTag], YKBooleanTagDeclaration, @"incorrectly cast to CFBoolean <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticNullCasting
{
    [p readString:@"- null\n- Null\n- NULL\n- ~\n- \n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertEqualObjects(value, [NSNull null], @"incorrectly cast to NSNull <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testExplicitNullCasting
{
    [p readString:@"- !!null 685230\n- !!null +685_230\n- !!null 02472256\n- !!null 0x_0A_74_AE\n" \
     "- !!null 0b1010_0111_0100_1010_1110\n- !!null 190:20:30\n- !!null 6.8523015e+5\n- !!null 685.230_15e+03\n" \
     "- !!null 685_230.15\n- !!null 190:20:30.15\n- !!null true\n- !!null True\n- !!null TRUE\n- !!null y\n" \
     "- !!null Y- !!null Yes\n- !!null YES\n- !!null yes\n- !!null on\n- !!null On\n- !!null ON\n" \
     "- !!null false\n- !!null False\n- !!null FALSE\n- !!null n\n- !!null N\n- !!null No\n- !!null NO\n" \
     "- !!null off\n- !!null Off\n- !!null OFF\n- !!null 2001-12-14t21:59:43.10-05:00\n" \
     "- !!null 2001-12-14 21:59:43.10 -5\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertEqualObjects(value, [NSNull null], @"incorrectly cast to NSNull <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testAutomaticTimestampCasting
{
    [p readString:@"- 2001-12-14t21:59:43.10-05:00\n- 2001-12-14 21:59:43.10 -5\n"];
    NSDate *date = [[NSDate dateWithString:@"2001-12-14 23:29:43 +0100"] dateByAddingTimeInterval:0.1];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }

    [p readString:@"- 2001-12-15T02:59:43.1Z\n- 2001-12-15 2:59:43.10\n"];
    date = [[NSDate dateWithString:@"2001-12-15 03:59:43 +0100"] dateByAddingTimeInterval:0.1];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }

    [p readString:@"- 2001-12-14\n"];
    date = [NSDate dateWithString:@"2001-12-14 01:00:00 +0100"];
    o = [[p parse] objectAtIndex:0];
    STAssertTrue([o count], @"parser returned nothing.");
    for (id value in o) {
        STAssertEqualObjects(value, date, @"incorrectly cast to NSDate <%@(%@)>", NSStringFromClass([value class]), value);
    }
}

- (void)testExplicitBinaryCasting
{
    NSString *testdataFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test" ofType:@"bin"];
    NSAssert(testdataFilePath, @"Unable to find test.bin file.");
    NSData *data = [NSData dataWithContentsOfFile:testdataFilePath];

    [p readString:@"- !!binary \"\n" \
     "  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\\\n" \
     "  OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\\\n" \
     "  +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\\\n" \
     "  AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=\"\n"
     "- !!binary |\n" \
     "  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5\n" \
     "  OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+\n" \
     "  +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC\n" \
     "  AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=\n"];
    NSError *scopeError = nil;
    NSArray *o = [[p parseWithError:&scopeError] objectAtIndex:0];
    STAssertNotNil(o, @"parser returned nothing, error %@", [scopeError userInfo]);
    for (id value in o) {
        STAssertEqualObjects(value, data, @"unexpected data value %@", value);
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
