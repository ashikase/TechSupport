/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSPackageCache.h"

#import "TSPackage.h"

@implementation TSPackageCache {
    NSMutableDictionary *filepathBasedCache_;
    NSMutableDictionary *identifierBasedCache_;
}

+ (instancetype)sharedCache {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

#pragma mark - Creation & Destruction

- (id)init {
    self = [super init];
    if (self != nil) {
        filepathBasedCache_ = [NSMutableDictionary new];
        identifierBasedCache_ = [NSMutableDictionary new];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning)
            name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [filepathBasedCache_ release];
    [identifierBasedCache_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [self removeAllObjects];
}

#pragma mark - Public API

- (TSPackage *)packageForFile:(NSString *)filepath {
    TSPackage *package = [filepathBasedCache_ objectForKey:filepath];
    if (package == nil) {
        package = [TSPackage packageForFile:filepath];
        [self cachePackage:package forFile:filepath];
    }
    return package;
}

- (TSPackage *)packageWithIdentifier:(NSString *)identifier {
    TSPackage *package = [identifierBasedCache_ objectForKey:identifier];
    if (package == nil) {
        package = [TSPackage packageWithIdentifier:identifier];
        [self cachePackage:package forIdentifier:identifier];
    }
    return package;
}

#pragma mark - Private API

- (void)cachePackage:(TSPackage *)package forFile:(NSString *)filepath {
    if (package != nil) {
        [filepathBasedCache_ setObject:package forKey:filepath];
    }
}

- (void)cachePackage:(TSPackage *)package forIdentifier:(NSString *)identifier {
    if (package != nil) {
        [identifierBasedCache_ setObject:package forKey:identifier];
    }
}

- (void)removeAllObjects {
    [filepathBasedCache_ removeAllObjects];
    [identifierBasedCache_ removeAllObjects];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
