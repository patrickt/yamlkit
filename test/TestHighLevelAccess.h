//
//  TestHighLevelAccess.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <SenTestingKit/SenTestingKit.h>
#import <YAMLKit/YAMLKit.h>

@interface TestHighLevelAccess : SenTestCase {

}

- (void)testStringLoading;
- (void)testStringDumping;
- (void)testFileDumpingAndLoading;
- (void)testLoadNilAndEmpty;

@end
