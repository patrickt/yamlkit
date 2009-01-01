//
//  TestEmitting.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestEmitting.h"
#import "YAMLKit.h"

@implementation TestEmitting

- (void)testSimpleEmitting
{
    YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
    [e emitItem:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
    NSString *str = [e emittedString];
    NSString *expected = @"- One\n- Two\n- Three\n";
	STAssertNotNil(str, @"Did not get a result from emitting");
    STAssertEqualObjects(str, expected, @"Recieved incorrect result from emitting");
}

- (void)testExplicitDelimitation
{
	YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
	[e setUsesExplicitDelimiters:YES];
	[e emitItem:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
	NSString *expected = @"---\n- One\n- Two\n- Three\n...\n";
	STAssertEqualObjects([e emittedString], expected, @"Did not display document beginnings and endings correctly");
}

@end
