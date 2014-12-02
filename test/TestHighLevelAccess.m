//
//  TestHighLevelAccess.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestHighLevelAccess.h"

@implementation TestHighLevelAccess

- (void)testStringDumping
{
	NSArray *a = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
	NSString *dumped = [YAMLKit dumpObject:a];
	XCTAssertEqualObjects(dumped, @"- one\n- two\n- three\n", @"was not the same when dumped");
}

- (void)testStringLoading
{
	NSString *dumped = @"- one\n- two\n- three";
	NSArray *a = [YAMLKit loadFromString:dumped];
	NSArray *b = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
	XCTAssertEqualObjects(a, b, @"was not the same when loaded");
}

- (void)testFileDumpingAndLoading
{
	NSArray *a = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
	NSString *path = @"/tmp/yamlkit_test.yaml";
	XCTAssertTrue([YAMLKit dumpObject:a toFile:path], @"did not dump successfully");
	XCTAssertEqualObjects(a, [YAMLKit loadFromFile:path], @"was not the same when loaded");
}


@end
