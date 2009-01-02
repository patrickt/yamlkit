//
//  TestParsing.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestParsing.h"
#import "YAMLKit.h"

@implementation TestParsing

- (void)setUp
{
    p = [[[YKParser alloc] init] autorelease];
}

- (void)testVerySimpleLoadingFromFile
{
    [p readFile:@"test/verysimple.yaml"];
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

- (void)testModerateLoadingFromFile
{
    [p readFile:@"test/moderate.yaml"];
	NSArray *o = [p parse];
	STAssertNotNil(o, @"#parse method failed to return anything.");
	NSDictionary *first = [o objectAtIndex:0];
	STAssertEqualObjects([first objectForKey:@"receipt"], @"Oz-Ware Purchase Invoice", @"recieved incorrect data from loaded YAML");
}

- (void)testAutomaticIntegerCasting
{
    [p readString:@"- 1\n- 2\n- 3"];
	NSArray *o = [[p parse] objectAtIndex:0];
	STAssertTrue([[o objectAtIndex:0] isKindOfClass:[NSNumber class]], @"was not a number");
	STAssertEquals(1, [[o objectAtIndex:0] intValue], @"was not equal to 1");
}

- (void)testWithNonexistentFile
{
	STAssertFalse([p readFile:@"test/doesnotexist"], @"was not nil when created with a nonexistent file.");
}

@end
