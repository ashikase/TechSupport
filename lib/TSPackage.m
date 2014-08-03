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

#include <stdio.h>

@implementation TSPackage {
    NSArray *config_;
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

@dynamic preferencesAttachment;
@dynamic storeLink;
@dynamic supportLink;

#pragma mark - Creation and Destruction

+ (instancetype)packageForFile:(NSString *)path {
    return [[[self alloc] initForFile:path] autorelease];
}

- (instancetype)initForFile:(NSString *)path {
    self = [super init];
    if (self != nil) {
        // Determine identifier of the package that contains the specified file.
        // NOTE: We need the slow way or we need to compile the whole dpkg.
        //       Not worth it for a minor feature like this.
        FILE *f = popen([[NSString stringWithFormat:@"dpkg-query -S %@ | head -1", path] UTF8String], "r");
        if (f != NULL) {
            // NOTE: Since there's only 1 line, we can read until a , or : is hit.
            NSMutableData *data = [NSMutableData new];
            char buf[1025];
            size_t maxSize = (sizeof(buf) - 1);
            while (!feof(f)) {
                size_t actualSize = fread(buf, 1, maxSize, f);
                buf[actualSize] = '\0';
                size_t identifierSize = strcspn(buf, ",:");
                [data appendBytes:buf length:identifierSize];

                // TODO: What is the purpose of this line?
                if (identifierSize != maxSize) {
                    break;
                }
            }
            if ([data length] > 0) {
                identifier_ = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            [data release];
            pclose(f);
        }

        // Determine package type, name and author, and load optional config.
        if (identifier_ != nil) {
            // Is a dpkg.
            f = popen([[NSString stringWithFormat:@"dpkg-query -p %@ | grep -E \"^(Name|Author|Version):\"", identifier_] UTF8String], "r");
            if (f != NULL) {
                // Determine name, author and version.
                NSMutableData *data = [NSMutableData new];
                char buf[1025];
                size_t maxSize = (sizeof(buf) - 1);
                while (!feof(f)) {
                    if (fgets(buf, maxSize, f)) {
                        buf[maxSize] = '\0';

                        char *newlineLocation = strrchr(buf, '\n');
                        if (newlineLocation != NULL) {
                            [data appendBytes:buf length:(NSUInteger)(newlineLocation - buf)];

                            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            NSUInteger firstColon = [string rangeOfString:@":"].location;
                            if (firstColon != NSNotFound) {
                                NSUInteger length = [string length];
                                if (length > (firstColon + 1)) {
                                    NSCharacterSet *set = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
                                    NSRange range = NSMakeRange((firstColon + 1), (length - firstColon - 1));
                                    NSUInteger firstNonSpace = [string rangeOfCharacterFromSet:set options:0 range:range].location;
                                    NSString *value = [string substringFromIndex:firstNonSpace];
                                    if ([string hasPrefix:@"Name:"]) {
                                        name_ = [value retain];
                                    } else if ([string hasPrefix:@"Author:"]) {
                                        author_ = [value retain];
                                    } else {
                                        version_ = [value retain];
                                    }
                                }
                            }
                            [string release];
                            [data setLength:0];
                        } else {
                            [data appendBytes:buf length:maxSize];
                        }
                    }
                }
                [data release];
                pclose(f);
            }

            // Ensure that package has a name.
            if (name_ == nil) {
                // Use name of contained file.
                name_ = [[path lastPathComponent] retain];
            }

            // Determine store identifier.
            storeIdentifier_ = [identifier_ copy];

            // Store path to related Library directory.
            libraryPath_ = @"/var/mobile/Library";

            // Load commands from optional config file.
            NSMutableArray *config = [NSMutableArray new];
            NSString *configFile = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.crash_reporter", identifier_];
            NSString *configString = [[NSString alloc] initWithContentsOfFile:configFile usedEncoding:NULL error:NULL];
            if ([configString length] > 0) {
                [config addObjectsFromArray:[configString componentsSeparatedByString:@"\n"]];
            }
            [configString release];

            config_ = config;
        } else {
            // Not a dpkg package. Check if it's an AppStore app.
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

                // Determine identifier, store identifier, name and author.
                NSString *metadataPath = [[appBundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"iTunesMetadata.plist"];
                NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile:metadataPath];
                identifier_ = [[metadata objectForKey:@"softwareVersionBundleId"] retain];
                storeIdentifier_ = [[metadata objectForKey:@"itemId"] retain];
                name_ = [[metadata objectForKey:@"itemName"] retain];
                author_ = [[metadata objectForKey:@"artistName"] retain];
                [metadata release];

                // Store path to related Library directory.
                libraryPath_ = [[[appBundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library"] retain];

                // Load commands from optional config file.
                NSMutableArray *config = [NSMutableArray new];
                NSString *configPath = [appBundlePath stringByAppendingPathComponent:@"crash_reporter"];
                NSString *configString = [[NSString alloc] initWithContentsOfFile:configPath usedEncoding:NULL error:NULL];
                if ([configString length] > 0) {
                    [config addObjectsFromArray:[configString componentsSeparatedByString:@"\n"]];
                }
                [configString release];

                config_ = config;
            } else {
                // Was not installed via either Cydia (dpkg) or AppStore; unsupported.
                [self release];
                return nil;
            }
        }

        // Parse links stored in optional config file.
        // NOTE: Parse here in order to determine if a support link is provided.
        NSMutableArray *instructions = [NSMutableArray new];
        for (NSString *line in config_) {
            if ([line hasPrefix:@"link"]) {
                TSLinkInstruction *instruction = [TSLinkInstruction instructionWithLine:line];
                if (instruction != nil) {
                    if ([instruction isSupport]) {
                        if (supportLinkInstruction_ == nil) {
                            supportLinkInstruction_ = [instruction retain];
                        }
                    } else {
                        [instructions addObject:instruction];
                    }
                }
            }
        }
        otherLinks_ = instructions;
    }
    return self;
}

- (void)dealloc {
    [identifier_ release];
    [storeIdentifier_ release];
    [name_ release];
    [author_ release];
    [otherLinks_ release];
    [config_ release];
    [libraryPath_ release];
    [supportLinkInstruction_ release];
    [super dealloc];
}

#pragma mark - Properties

- (TSLinkInstruction *)storeLink {
    TSLinkInstruction *instruction = nil;

    NSString *line = nil;
    if ([self isAppStore]) {
        // Add App Store link.
        // NOTE: Must use long long here as there are over 2 billion apps on the App Store.
        long long item = [[self storeIdentifier] longLongValue];
        line = [[NSString alloc] initWithFormat:
            @"link url \"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%lld&mt=8\" as \"%@\"",
            item, NSLocalizedString(@"VIEW_IN_APP_STORE", nil)];
    } else {
        // Add Cydia link.
        line = [[NSString alloc] initWithFormat:@"link url \"cydia://package/%@\" as \"%@\"",
            [self storeIdentifier], NSLocalizedString(@"VIEW_IN_CYDIA", nil)];
    }

    if (line != nil) {
        instruction = [TSLinkInstruction instructionWithLine:line];
        [line release];
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
                        NSString *line = [[NSString alloc] initWithFormat:@"link email %@ as \"%@\" is_support",
                                 emailAddress, NSLocalizedString(@"CONTACT_AUTHOR", nil)];
                        instruction = [TSLinkInstruction instructionWithLine:line];
                        [line release];
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
        NSString *line = [[NSString alloc] initWithFormat:@"include as Preferences plist \"%@\"", filepath];
        instruction = [TSIncludeInstruction instructionWithLine:line];
        [line release];
    }
    [subpath release];

    return instruction;
}

- (NSArray *)otherAttachments {
    NSMutableArray *instructions = [NSMutableArray new];

    for (NSString *line in config_) {
        if ([line hasPrefix:@"include"]) {
            TSIncludeInstruction *instruction = [TSIncludeInstruction instructionWithLine:line];
            if (instruction != nil) {
                [instructions addObject:instruction];
            }
        }
    }

    return instructions;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
