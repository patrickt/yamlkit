//
//  TestParsing.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestParsing.h"
#import "YAMLKit.h"

@implementation TestParsing

- (void)testVerySimpleLoadingFromFile
{
	YKParser *p = [[YKParser alloc] initWithFile:@"test/verysimple.yaml"];
	id o = [p parse];
	STAssertNotNil(o, @"#parse method failed to return anything.");
	NSArray *needed = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Escape of the Unicorn" forKey:@"title"]];
	STAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
	[p release];
}

- (void)testVerySimpleStringParsing
{
	YKParser *p = [[YKParser alloc] initWithString:@"- foo\n- bar\n- baz"];
	id o = [p parse];
	STAssertNotNil(o, @"#parse method failed to return anything.");
    NSArray *needed = [NSArray arrayWithObject: [NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil]];
    STAssertEqualObjects(o, needed, @"#parse returned an incorrect object");
	[p release];
}

- (void)testModerateLoadingFromFile
{
	YKParser *p = [[YKParser alloc] initWithFile:@"test/moderate.yaml"];
	NSArray *o = [p parse];
	STAssertNotNil(o, @"#parse method failed to return anything.");
	NSDictionary *first = [o objectAtIndex:0];
	STAssertEqualObjects([first objectForKey:@"receipt"], @"Oz-Ware Purchase Invoice", @"recieved incorrect data from loaded YAML");
}

@end
