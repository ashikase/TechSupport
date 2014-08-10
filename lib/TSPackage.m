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

#import "TSIncludeInstruction.h"
#import "TSLinkInstruction.h"
#import "dpkg_util.h"

#include <sys/stat.h>

@implementation TSPackage {
    NSString *bundlePath_;
    NSString *libraryPath_;
    TSLinkInstruction *supportLinkInstruction_;
}

@synthesize identifier = identifier_;
@synthesize storeIdentifier = storeIdentifier_;
@synthesize name = name_;
@synthesize author = author_;
@synthesize version = version_;
@synthesize isAppStore = isAppStore_;
@synthesize otherLinks = otherLinks_;
@synthesize otherAttachments = otherAttachments_;

@dynamic preferencesAttachment;
@dynamic storeLink;
@dynamic supportLink;

#pragma mark - Creation and Destruction

static void initDebianPackage(TSPackage *self) {
    // Determine package name, author and version.
    NSDictionary *details = detailsForDebianPackageWithIdentifier(self->identifier_);
    self->name_ = [[details objectForKey:@"Name"] retain];
    self->author_ = [[details objectForKey:@"Author"] retain];
    self->version_ = [[details objectForKey:@"Version"] retain];

    // Determine store identifier.
    self->storeIdentifier_ = [self->identifier_ copy];

}

static void initCommon(TSPackage *self) {
    NSString *configPath = nil;
    if (self->isAppStore_) {
        // Store path to related Library directory.
        self->libraryPath_ = [[[self->bundlePath_ stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library"] retain];

        // Determine path to related optional config file.
        configPath = [self->bundlePath_ stringByAppendingPathComponent:@"crash_reporter"];
    } else {
        // Store path to related Library directory.
        self->libraryPath_ = @"/var/mobile/Library";

        // Determine path to related optional config file.
        configPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.crash_reporter", self->identifier_];
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

+ (instancetype)packageForFile:(NSString *)path {
    return [[[self alloc] initForFile:path] autorelease];
}

+ (instancetype)packageWithIdentifier:(NSString *)identifier {
    return [[[self alloc] initWithIdentifier:identifier] autorelease];
}

- (instancetype)initForFile:(NSString *)path {
    self = [super init];
    if (self != nil) {
        // Determine identifier of the package that contains the specified file.
        identifier_ = identifierForDebianPackageContainingFile(path);

        // Determine package type, name and author, and load optional config.
        if (identifier_ != nil) {
            // Is a dpkg.
            initDebianPackage(self);

            // Ensure that package has a name.
            if (name_ == nil) {
                // Use name of contained file.
                name_ = [[path lastPathComponent] retain];
            }
        } else {
            // Not a dpkg package. Check if it's an App Store app.
            if ([path hasPrefix:@"/var/mobile/Applications/"]) {
                // Check if any component in the path has a .app suffix.
                NSString *appBundlePath = path;
                do {
                    appBundlePath = [appBundlePath stringByDeletingLastPathComponent];
                    if ([appBundlePath length] == 0) {
                        [self release];
                        return nil;
                    }
                } while (![appBundlePath hasSuffix:@".app"]);

                // If we made it this far, this is an AppStore package.
                isAppStore_ = YES;
                bundlePath_ = [appBundlePath retain];

                // Determine identifier, store identifier, name and author.
                NSString *metadataPath = [[appBundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"iTunesMetadata.plist"];
                NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile:metadataPath];
                identifier_ = [[metadata objectForKey:@"softwareVersionBundleId"] retain];
                storeIdentifier_ = [[metadata objectForKey:@"itemId"] retain];
                name_ = [[metadata objectForKey:@"itemName"] retain];
                author_ = [[metadata objectForKey:@"artistName"] retain];
                [metadata release];
            } else {
                // Was not installed via either Cydia (dpkg) or App Store; unsupported.
                [self release];
                return nil;
            }
        }

        // Load optional config.
        initCommon(self);
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self != nil) {
        // Store the package identifier.
        identifier_ = [identifier copy];

        // Determine type of package.
        NSString *filepath = [[NSString alloc] initWithFormat:@"/var/lib/dpkg/info/%@.list", identifier];
        struct stat buf;
        BOOL isDpkg = (stat([filepath UTF8String], &buf) == 0);
        [filepath release];

        // Determine package type, name and author.
        if (isDpkg) {
            // Is a dpkg.
            initDebianPackage(self);

            // Ensure that package has a name.
            if (self->name_ == nil) {
                // Use name of contained file.
                self->name_ = [identifier retain];
            }
        } else {
            // Not a dpkg package. Check if it's an App Store app.
            NSFileManager *fileMan = [NSFileManager defaultManager];
            NSError *error = nil;
            NSArray *contents = [fileMan contentsOfDirectoryAtPath:@"/var/mobile/Applications" error:&error];
            if (contents != nil) {
                for (NSString *path in contents) {
                    NSString *metadataPath = [path stringByAppendingPathComponent:@"iTunesMetadata.plist"];
                    NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile:metadataPath];
                    if (metadata != nil) {
                        if ([[metadata objectForKey:@"softwareVersionBundleId"] isEqualToString:identifier]) {
                            // Found the package. Determine the bundle path.
                            NSArray *subcontents = [fileMan contentsOfDirectoryAtPath:path error:&error];
                            if (subcontents != nil) {
                                for (NSString *subpath in subcontents) {
                                    if ([subpath hasSuffix:@".app"]) {
                                        isAppStore_ = YES;
                                        bundlePath_ = [subpath retain];

                                        // Determine store identifier, name and author.
                                        storeIdentifier_ = [[metadata objectForKey:@"itemId"] retain];
                                        name_ = [[metadata objectForKey:@"itemName"] retain];
                                        author_ = [[metadata objectForKey:@"artistName"] retain];

                                        // Stop searching subcontents.
                                        break;
                                    }
                                }
                            } else {
                                NSLog(@"ERROR: Failed to get contents of App Store app's container: %@.", [error localizedDescription]);
                            }
                        }
                        [metadata release];

                        if (isAppStore_) {
                            // Stop searching contents.
                            break;
                        }
                    }
                }
            } else {
                NSLog(@"ERROR: Failed to get contents of App Store apps directory: %@.", [error localizedDescription]);
            }

            if (!isAppStore_) {
                // Was not installed via either Cydia (dpkg) or App Store; unsupported.
                [self release];
                return nil;
            }
        }

        // Load optional config.
        initCommon(self);
    }
    return self;
}

- (void)dealloc {
    [identifier_ release];
    [storeIdentifier_ release];
    [name_ release];
    [author_ release];
    [otherLinks_ release];
    [otherAttachments_ release];
    [bundlePath_ release];
    [libraryPath_ release];
    [supportLinkInstruction_ release];
    [super dealloc];
}

#pragma mark - Properties

- (TSLinkInstruction *)storeLink {
    TSLinkInstruction *instruction = nil;

    NSString *string = nil;
    if ([self isAppStore]) {
        // Add App Store link.
        // NOTE: Must use long long here as there are over 2 billion apps on the App Store.
        long long item = [[self storeIdentifier] longLongValue];
        string = [[NSString alloc] initWithFormat:
            @"link url \"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%lld&mt=8\" as \"%@\"",
            item, NSLocalizedString(@"VIEW_IN_APP_STORE", nil)];
    } else {
        // Add Cydia link.
        string = [[NSString alloc] initWithFormat:@"link url \"cydia://package/%@\" as \"%@\"",
            [self storeIdentifier], NSLocalizedString(@"VIEW_IN_CYDIA", nil)];
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
        NSString *author = [self author];
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

    NSString *subpath = [[NSString alloc] initWithFormat:@"Preferences/%@.plist", identifier_];
    NSString *filepath = [libraryPath_ stringByAppendingPathComponent:subpath];
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
