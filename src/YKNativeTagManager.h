//
//  YKNativeTagManager.h
//  YAMLKit
//
//  Created by Faustino Osuna on 10/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YAMLKit/YKTag.h>

@interface YKNativeTagManager : NSObject <YKTagDelegate> {
    NSDictionary *tagsByName;
}

+ (id)sharedManager;

@property (readonly) NSDictionary *tagsByName;

@end
