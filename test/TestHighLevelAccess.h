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
- (void)testFileLoading;

- (void)testStringDumping;
- (void)testFileDumping;

@end
