/*
 *  YAMLKit.h
 *  YAMLKit
 *
 *  Created by Patrick Thomson on 12/29/08.
 *  Copyright 2008 Patrick Thomson. All rights reserved.
 *
 */

#import <YAMLKit/NSData+Base64.h>
#import <YAMLKit/YKParser.h>
#import <YAMLKit/YKEmitter.h>
#import <YAMLKit/YKUnknownNode.h>

@interface YAMLKit : NSObject
{

}
#pragma mark Parser
+ (id)loadFromString:(NSString *)aString;
+ (id)loadFromFile:(NSString *)path;
+ (id)loadFromURL:(NSURL *)url;

#pragma mark Emitter
+ (NSString *)dumpObject:(id)object;
+ (BOOL)dumpObject:(id)object toFile:(NSString *)path;
+ (BOOL)dumpObject:(id)object toURL:(NSURL *)path;

@end
