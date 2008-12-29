/*
 *  YAMLKit.h
 *  YAMLKit
 *
 *  Created by Patrick Thomson on 12/29/08.
 *  Copyright 2008 Patrick Thomson. All rights reserved.
 *
 */

@interface YAMLKit : NSObject
{
    
}

+ (NSString *)dump:(id)object;
+ (id)load:(NSString *)aString;


@end
