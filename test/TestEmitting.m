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

@end
