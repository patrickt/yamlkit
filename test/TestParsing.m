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
    [p readFile:@"test/verysimple.yaml"];
	id o = [p parse];
	XCTAssertNotNil(o, @"#parse method failed to return anything.");
	NSArray *needed = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Escape of the Unicorn" forKey:@"title"]];
	XCTAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testVerySimpleStringParsing
{
	[p readString:@"- foo\n- bar\n- baz"];
	id o = [p parse];
	XCTAssertNotNil(o, @"#parse method failed to return anything.");
    NSArray *needed = [NSArray arrayWithObject: [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil]];
    XCTAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testDigitPrefixedStringParsing
{
	[p readString:@"- 325de3fa"];
	id o = [p parse];
	XCTAssertNotNil(o, @"#parse method failed to return anything.");
	NSArray *needed = [NSArray arrayWithObject: [NSArray arrayWithObjects:@"325de3fa", nil]];
	XCTAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
}

- (void)testModerateLoadingFromFile
{
    [p readFile:@"test/moderate.yaml"];
	NSArray *o = [p parse];
	XCTAssertNotNil(o, @"#parse method failed to return anything.");
	NSDictionary *first = [o objectAtIndex:0];
	XCTAssertEqualObjects([first objectForKey:@"receipt"], @"Oz-Ware Purchase Invoice", @"recieved incorrect data from loaded YAML");
	XCTAssertTrue(([[first objectForKey:@"specialDelivery"] length] > 25), @"did not parse a multiline string correctly");
}

- (void)testAutomaticIntegerCasting
{
    [p readString:@"- 1\n- 2\n- 3"];
	NSArray *o = [[p parse] objectAtIndex:0];
	XCTAssertTrue([[o objectAtIndex:0] isKindOfClass:[NSNumber class]], @"was not a number");
	XCTAssertEqual(1, [[o objectAtIndex:0] intValue], @"was not equal to 1");
}

- (void)testAutomaticDoubleCasting
{
    [p readString:@"- 1.5\n"];
	NSArray *o = [[p parse] objectAtIndex:0];
	XCTAssertTrue([[o objectAtIndex:0] isKindOfClass:[NSNumber class]], @"was not a number");
	XCTAssertEqualObjects([o objectAtIndex:0], [NSNumber numberWithDouble:1.5], @"incorrectly cast to NSNumber");
}

- (void)testAutomaticBooleanCasting
{
    [p readString:@"- true\n- True\n- TRUE\n- y\n- Y\n- Yes\n- YES\n- yes\n- on\n- On\n- ON\n"];
	NSArray *o = [[p parse] objectAtIndex:0];
	for(id value in o) {
		if([value isKindOfClass:[NSNumber class]]) {
			XCTAssertTrue([value boolValue], @"boolean value was not true");
		} else {
			XCTFail(@"was not a boolean");
		}
	}
    [p readString:@"- false\n- False\n- FALSE\n- n\n- N\n- No\n- NO\n- off\n- Off\n- OFF\n"];
	o = [[p parse] objectAtIndex:0];
	for(id value in o) {
		if([value isKindOfClass:[NSNumber class]]) {
			XCTAssertFalse([value boolValue], @"boolean value was not false");
		} else {
			XCTFail(@"was not a boolean");
		}
	}
}

- (void)testWithNonexistentFile
{
	XCTAssertFalse([p readFile:@"test/doesnotexist"], @"#readFile returned true when given a nonexistent file");
	XCTAssertFalse([p readyToParse], @"returned a false value for #readyToParse");
	NSError *e;
	NSArray *o = [p parseWithError:&e];
	XCTAssertNil(o, @"did not return nil when everything went wrong.");
	XCTAssertEqualObjects([e domain], @"YKErrorDomain", @"returned a different error domain");
}

@end
