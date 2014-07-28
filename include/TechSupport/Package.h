/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import <Foundation/Foundation.h>

@interface Package : NSObject
@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, readonly) NSString *storeIdentifier;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *author;
@property(nonatomic, readonly) NSString *version;
@property(nonatomic, readonly) NSArray *config;
@property(nonatomic, readonly) BOOL isAppStore;
+ (instancetype)packageForFile:(NSString *)path;
@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
