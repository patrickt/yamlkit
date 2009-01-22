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
	
	NSString *dumped = [YAMLKit dump:a];
	STAssertEqualObjects(dumped, @"- one\n- two\n- three\n", @"was not the same when dumped");
}

- (void)testStringLoading
{
	NSString *dumped = @"- one\n- two\n- three";
	NSArray *a = [YAMLKit load:dumped];
	NSArray *b = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
	STAssertEqualObjects(a, b, @"was not the same when loaded");
}

@end
