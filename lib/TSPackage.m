/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

// Referenced from searchfiles() of query.c of the dpkg source package.

#import "TSPackage.h"

#import <libpackageinfo/libpackageinfo.h>
#import "TSIncludeInstruction.h"
#import "TSLinkInstruction.h"

#include <sys/stat.h>

@implementation TSPackage {
    PIPackage *package_;
    TSLinkInstruction *supportLinkInstruction_;
}

@synthesize otherLinks = otherLinks_;
@synthesize otherAttachments = otherAttachments_;

@dynamic isAppStore;
@dynamic preferencesAttachment;
@dynamic storeLink;
@dynamic supportLink;

#pragma mark - Creation and Destruction

+ (instancetype)packageForFile:(NSString *)path {
    return [[[self alloc] initForFile:path] autorelease];
}

+ (instancetype)packageWithIdentifier:(NSString *)identifier {
    return [[[self alloc] initWithIdentifier:identifier] autorelease];
}

- (instancetype)initForFile:(NSString *)path {
    self = [super init];
    if (self != nil) {
        package_ = [[PIPackageCache sharedCache] packageForFile:path];
        loadConfiguration(self);
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self != nil) {
        package_ = [[PIPackageCache sharedCache] packageWithIdentifier:identifier];
        loadConfiguration(self);
    }
    return self;
}

static void loadConfiguration(TSPackage *self) {
    NSString *configPath = nil;
    if ([self->package_ isKindOfClass:[PIApplePackage class]]) {
        // Determine path to related optional config file.
        configPath = [[self->package_ bundlePath] stringByAppendingPathComponent:@"crash_reporter"];
    } else {
        // Determine path to related optional config file.
        configPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.crash_reporter", [self->package_ identifier]];
    }

    // Parse includes and links stored in optional config file.
    // NOTE: Parse here in order to determine if a support link is provided.
    NSString *configString = [[NSString alloc] initWithContentsOfFile:configPath usedEncoding:NULL error:NULL];
    if ([configString length] > 0) {
        NSMutableArray *includeInstructions = [NSMutableArray new];
        NSMutableArray *linkInstructions = [NSMutableArray new];
        for (NSString *string in [configString componentsSeparatedByString:@"\n"]) {
            if ([string hasPrefix:@"include"]) {
                TSIncludeInstruction *instruction = [TSIncludeInstruction instructionWithString:string];
                if (instruction != nil) {
                    [includeInstructions addObject:instruction];
                }
            } else if ([string hasPrefix:@"link"]) {
                TSLinkInstruction *instruction = [TSLinkInstruction instructionWithString:string];
                if (instruction != nil) {
                    if ([instruction isSupport]) {
                        if (self->supportLinkInstruction_ == nil) {
                            self->supportLinkInstruction_ = [instruction retain];
                        }
                    } else {
                        [linkInstructions addObject:instruction];
                    }
                }
            }
        }
        self->otherAttachments_ = includeInstructions;
        self->otherLinks_ = linkInstructions;
    }
    [configString release];
}

- (void)dealloc {
    [package_ release];
    [otherLinks_ release];
    [otherAttachments_ release];
    [supportLinkInstruction_ release];
    [super dealloc];
}

#pragma mark - Properties

- (NSString *)identifier {
    return [package_ identifier];
}

- (NSString *)storeIdentifier {
    return [package_ storeIdentifier];
}

- (NSString *)name {
    return [package_ name];
}

- (NSString *)author {
    return [package_ author];
}

- (NSString *)version {
    return [package_ version];
}

- (NSDate *)installDate {
    return [package_ installDate];
}

- (BOOL)isAppStore {
    return [package_ isKindOfClass:[PIAppleStorePackage class]];
}

- (TSLinkInstruction *)storeLink {
    TSLinkInstruction *instruction = nil;

    NSString *string = nil;
    if ([self isAppStore]) {
        // Add App Store link.
        // NOTE: Must use long long here as there are over 2 billion apps on the App Store.
        long long item = [[package_ storeIdentifier] longLongValue];
        string = [[NSString alloc] initWithFormat:
            @"link url \"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%lld&mt=8\" as \"%@\"",
            item, NSLocalizedString(@"VIEW_IN_APP_STORE", nil)];
    } else {
        // Add Cydia link.
        string = [[NSString alloc] initWithFormat:@"link url \"cydia://package/%@\" as \"%@\"",
            [package_ storeIdentifier], NSLocalizedString(@"VIEW_IN_CYDIA", nil)];
    }

    if (string != nil) {
        instruction = [TSLinkInstruction instructionWithString:string];
        [string release];
    }

    return instruction;
}

- (TSLinkInstruction *)supportLink {
    TSLinkInstruction *instruction = nil;

    if (supportLinkInstruction_ != nil) {
        return supportLinkInstruction_;
    } else {
        // Return email link to contact author.
        NSString *author = [package_ author];
        if (author != nil) {
            NSRange leftAngleRange = [author rangeOfString:@"<" options:NSBackwardsSearch];
            if (leftAngleRange.location != NSNotFound) {
                NSRange rightAngleRange = [author rangeOfString:@">" options:NSBackwardsSearch];
                if (rightAngleRange.location != NSNotFound) {
                    if (leftAngleRange.location < rightAngleRange.location) {
                        NSRange range = NSMakeRange(leftAngleRange.location + 1, rightAngleRange.location - leftAngleRange.location - 1);
                        NSString *emailAddress = [author substringWithRange:range];
                        NSString *string = [[NSString alloc] initWithFormat:@"link email %@ as \"%@\" is_support",
                                 emailAddress, NSLocalizedString(@"CONTACT_AUTHOR", nil)];
                        instruction = [TSLinkInstruction instructionWithString:string];
                        [string release];
                    }
                }
            }
        }
    }

    return instruction;
}

- (TSIncludeInstruction *)preferencesAttachment {
    TSIncludeInstruction *instruction = nil;

    NSString *subpath = [[NSString alloc] initWithFormat:@"Preferences/%@.plist", [package_ identifier]];
    NSString *filepath = [[package_ libraryPath] stringByAppendingPathComponent:subpath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        NSString *string = [[NSString alloc] initWithFormat:@"include as Preferences plist \"%@\"", filepath];
        instruction = [TSIncludeInstruction instructionWithString:string];
        [string release];
    }
    [subpath release];

    return instruction;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
