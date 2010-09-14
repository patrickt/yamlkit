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
    STAssertTrue([[first valueForKeyPath:@"canonical"] isEqualTo:[NSNumber numberWithInt:12345]], @"did not convert canonical <%@(%@)>", [first valueForKeyPath:@"canonical"], NSStringFromClass([[first valueForKeyPath:@"canonical"] class]));
    STAssertTrue([[first valueForKeyPath:@"decimal"] isEqualTo:[NSNumber numberWithInt:12345]], @"did not convert decimal <%@(%@)>", [first valueForKeyPath:@"decimal"], NSStringFromClass([[first valueForKeyPath:@"decimal"] class]));
    STAssertTrue([[first valueForKeyPath:@"sexagesimal"] isEqualTo:[NSNumber numberWithInt:12345]], @"did not convert sexagesimal <%@(%@)>", [first valueForKeyPath:@"sexagesimal"], NSStringFromClass([[first valueForKeyPath:@"sexagesimal"] class]));
    STAssertTrue([[first valueForKeyPath:@"octal"] isEqualTo:[NSNumber numberWithInt:12]], @"did not convert octal <%@(%@)>", [first valueForKeyPath:@"octal"], NSStringFromClass([[first valueForKeyPath:@"octal"] class]));
    STAssertTrue([[first valueForKeyPath:@"hexadecimal"] isEqualTo:[NSNumber numberWithInt:12]], @"did not convert hexadecimal <%@(%@)>", [first valueForKeyPath:@"hexadecimal"], NSStringFromClass([[first valueForKeyPath:@"hexadecimal"] class]));
    STAssertTrue([[first valueForKeyPath:@"null"] isEqualTo:[NSNull null]], @"did not recognize null <%@,%@>", [first valueForKeyPath:@"null"], NSStringFromClass([[first valueForKeyPath:@"null"] class]));
    STAssertTrue([[first valueForKeyPath:@"true"] boolValue], @"did not recognize true <%@,%@>", [first valueForKeyPath:@"true"], NSStringFromClass([[first valueForKeyPath:@"true"] class]));
    STAssertFalse([[first valueForKeyPath:@"false"] boolValue], @"did not recognize false <%@,%@>", [first valueForKeyPath:@"false"], NSStringFromClass([[first valueForKeyPath:@"false"] class]));
    STAssertTrue([[first valueForKeyPath:@"string"] isEqualTo:@"12345"] && [[first valueForKeyPath:@"string"] isKindOfClass:[NSString class]], @"did not recognize string <%@,%@>", [first valueForKeyPath:@"string"], NSStringFromClass([[first valueForKeyPath:@"string"] class]));

    STAssertTrue([[first valueForKeyPath:@"float canonical"] isEqualTo:[NSNumber numberWithFloat:1.23015e+3]], @"did not recognize canonical <%@,%@>", [first valueForKeyPath:@"float canonical"], NSStringFromClass([[first valueForKeyPath:@"float canonical"] class]));
    STAssertTrue([[first valueForKeyPath:@"float exponential"] isEqualTo:[NSNumber numberWithFloat:12.3015e+02]], @"did not recognize exponential <%@,%@>", [first valueForKeyPath:@"float exponential"], NSStringFromClass([[first valueForKeyPath:@"float exponential"] class]));
    STAssertTrue([[first valueForKeyPath:@"float fixed"] isEqualTo:[NSNumber numberWithFloat:1230.15]], @"did not recognize fixed <%@,%@>", [first valueForKeyPath:@"float fixed"], NSStringFromClass([[first valueForKeyPath:@"float fixed"] class]));
}

- (void)testAutomaticIntegerCasting
{
    [p readString:@"- 1\n- 2\n- 3"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([[o objectAtIndex:0] isKindOfClass:[NSNumber class]], @"was not a number");
    STAssertEquals(1, [[o objectAtIndex:0] intValue], @"was not equal to 1");
}

- (void)testAutomaticDoubleCasting
{
    [p readString:@"- 1.5\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    STAssertTrue([[o objectAtIndex:0] isKindOfClass:[NSNumber class]], @"was not a number");
    STAssertEqualObjects([o objectAtIndex:0], [NSNumber numberWithDouble:1.5], @"incorrectly cast to NSNumber");
}

- (void)testAutomaticBooleanCasting
{
    [p readString:@"- true\n- True\n- TRUE\n- y\n- Y\n- Yes\n- YES\n- yes\n- on\n- On\n- ON\n"];
    NSArray *o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        if ([value isKindOfClass:[NSNumber class]]) {
            STAssertTrue([value boolValue], @"boolean value was not true");
        } else {
            STFail(@"was not a boolean");
        }
    }
    [p readString:@"- false\n- False\n- FALSE\n- n\n- N\n- No\n- NO\n- off\n- Off\n- OFF\n"];
    o = [[p parse] objectAtIndex:0];
    for (id value in o) {
        if ([value isKindOfClass:[NSNumber class]]) {
            STAssertFalse([value boolValue], @"boolean value was not false");
        } else {
            STFail(@"was not a boolean");
        }
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
