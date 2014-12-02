//
//  TestEmitting.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "TestEmitting.h"

@implementation TestEmitting

- (void)setUp
{
	e = [[[YKEmitter alloc] init] autorelease];
}

- (void)testSimpleEmitting
{
    [e emitItem:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
    NSString *str = [e emittedString];
    NSString *expected = @"- One\n- Two\n- Three\n";
	XCTAssertNotNil(str, @"Did not get a result from emitting");
    XCTAssertEqualObjects(str, expected, @"Recieved incorrect result from emitting");
}

- (void)testExplicitDelimitation
{
	[e setUsesExplicitDelimiters:YES];
	[e emitItem:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
	NSString *expected = @"---\n- One\n- Two\n- Three\n...\n";
	XCTAssertEqualObjects([e emittedString], expected, @"Did not display document beginnings and endings correctly");
}

//- (void)testDifferentEncodings
//{
//    YKEmitter *e2 = [[YKEmitter alloc] initWithEncoding:NSUTF8StringEncoding];
//	[e2 emitItem:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
//	NSData *data = [e2 emittedData];
//	NSString *derived = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//	NSString *expected = @"- One\n- Two\n- Three\n";
//	// the substringFromIndex is to ignore the UTF16 BOM
//	XCTAssertEqualObjects([derived substringFromIndex:0], expected, @"choked when given a UTF-16 encoding.");
//}

@end
