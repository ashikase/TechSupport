/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSIncludeInstruction.h"

#include <sys/stat.h>
#include <sys/types.h>

static NSString *mimeTypeForExtension(NSString *extension) {
    NSDictionary *mimeTypes = @{
        // Plain Text
        @"txt"  : @"text/plain",

        // Plain Binary
        @"bin"  : @"application/octet-stream",

        // Archives
        @"bz"   : @"application/x-bzip",
        @"bz2"  : @"application/x-bzip2",
        @"deb"  : @"application/x-debian-package",
        @"tar"  : @"application/x-tar",
        @"zip"  : @"application/zip",

        // Audio
        @"aac"  : @"audio/x-aac",
        @"aif"  : @"audio/x-aiff",
        @"aiff" : @"audio/x-aiff",
        @"mp3"  : @"audio/x-mpeg",
        @"wav"  : @"audio/x-wav",

        // Fonts
        @"ttf"  : @"application/x-font-ttf",

        // Images
        @"bmp"  : @"image/bmp",
        @"gif"  : @"image/gif",
        @"jpg"  : @"image/jpeg",
        @"jpeg" : @"image/jpeg",
        @"png"  : @"image/png",
        @"svg"  : @"image/svg+xml",

        // Text
        @"css"  : @"text/css",
        @"csv"  : @"text/csv",
        @"html" : @"text/html",
        @"js"   : @"application/javascript",
        @"json" : @"application/json",
        @"sh"   : @"application/x-sh",
        @"tsv"  : @"text/tab-separated-values",
        @"xml"  : @"application/xml",
        @"yaml" : @"text/yaml"
    };
    return [mimeTypes objectForKey:extension];
}

@interface TSInstruction (Private)
@property(nonatomic, copy) NSString *title;
@end

@implementation TSIncludeInstruction

@synthesize content = content_;
@synthesize command = command_;
@synthesize filepath = filepath_;
@synthesize mimeType = mimeType_;
@synthesize includeType = includeType_;

// NOTE: Format is:
//
//       include [as <title>] [mimetype <mimetype>] command <command>
//       include [as <title>] [mimetype <mimetype>] file <filename>
//       include [as <title>] [mimetype <mimetype>] plist <filename>
//
- (instancetype)initWithTokens:(NSArray *)tokens {
    self = [super initWithTokens:tokens];
    if (self != nil) {
        NSString *title = nil;
        NSString *argument = nil;

        enum {
            ModeAttribute,
            ModeMimeType,
            ModeTitle,
            ModeTypeArgument
        } mode = ModeAttribute;

        NSUInteger count = [tokens count];
        NSUInteger index;
        for (index = 0; index < count; ++index) {
            NSString *token = [tokens objectAtIndex:index];
            switch (mode) {
                case ModeAttribute:
                    if ([token isEqualToString:@"as"]) {
                        mode = ModeTitle;
                    } else if ([token isEqualToString:@"mimetype"]) {
                        mode = ModeMimeType;
                    } else if ([token isEqualToString:@"command"]) {
                        includeType_ = TSIncludeInstructionTypeCommand;
                        mode = ModeTypeArgument;
                    } else if ([token isEqualToString:@"file"]) {
                        includeType_ = TSIncludeInstructionTypeFile;
                        mode = ModeTypeArgument;
                    } else if ([token isEqualToString:@"plist"]) {
                        includeType_ = TSIncludeInstructionTypePlist;
                        mode = ModeTypeArgument;
                    }
                    break;
                case ModeMimeType:
                    mimeType_ = [stripQuotes(token) retain];
                    mode = ModeAttribute;
                    break;
                case ModeTitle:
                    title = stripQuotes(token);
                    mode = ModeAttribute;
                    break;
                case ModeTypeArgument:
                    goto loop_exit;
                default:
                    break;
            }
        }

loop_exit:
        argument = stripQuotes([[tokens subarrayWithRange:NSMakeRange(index, (count - index))] componentsJoinedByString:@" "]);
        if (includeType_ == TSIncludeInstructionTypeCommand) {
            command_ = [argument retain];
        } else {
            filepath_ = [argument retain];
        }
        [self setTitle:(title ?: argument)];
    }
    return self;
}

- (void)dealloc {
    [content_ release];
    [command_ release];
    [filepath_ release];
    [mimeType_ release];
    [super dealloc];
}

- (NSData *)content {
    if (content_ == nil) {
        if (includeType_ == TSIncludeInstructionTypeFile) {
            // Return contents of file.
            NSString *filepath = [self filepath];
            NSError *error = nil;
            content_ = [[NSData alloc] initWithContentsOfFile:filepath options:0 error:&error];
            if (content_ == nil) {
                LOGE("Unable to load contents of file \"%@\": \"%@\".", filepath, [error localizedDescription]);
            }
        } else if (includeType_ == TSIncludeInstructionTypePlist) {
            // Return contents of property list, converted to a legible format.
            NSString *filepath = [self filepath];
            NSError *error = nil;
            NSData *data = [[NSData alloc] initWithContentsOfFile:filepath options:0 error:&error];
            if (data != nil) {
                id plist = nil;
                if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)]) {
                    plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
                } else {
                    plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:NULL errorDescription:NULL];
                }
                content_ = [[[plist description] dataUsingEncoding:NSUTF8StringEncoding] retain];
            } else {
                LOGE("Unable to load data from \"%@\": \"%@\".", filepath, [error localizedDescription]);
            }
        } else {
            // Return the output of a command.
            const char *command = [[self command] UTF8String];

            // Determine if command is multiline (i.e. a script).
            char *newline = strstr(command, "\n");
            if (newline != NULL) {
                // Determine available filepath for a temporary file.
                char tempFilepath[PATH_MAX];
                strcpy(tempFilepath, "/tmp/crashreporter.XXXXXX");
                int fd = mkstemp(tempFilepath);
                if (fd == -1) {
                    LOGE("Unable to create temporary file to store command script.");
                    return nil;
                }

                // Write command script to temporary file.
                size_t nbyte = strlen(command);
                ssize_t bytesWritten = write(fd, command, nbyte);
                if (bytesWritten != nbyte) {
                    LOGE("Failed to write command script to temporary file.");
                    close(fd);
                    return nil;
                }

                // Set command script as executable (and read-only).
                int result = fchmod(fd, S_IXUSR | S_IRUSR);
                if (result != 0) {
                    LOGE(@"Failed to set command script file as executable.");
                    close(fd);
                    return nil;
                }

                close(fd);

                // Set command to run.
                command = tempFilepath;
            }

            fflush(stdout);
            FILE *f = popen(command, "r");
            if (f == NULL) {
                LOGE("Failed to run command.");
                return nil;
            }

            NSMutableString *string = [NSMutableString new];
            while (!feof(f)) {
                char buf[1024];
                size_t charsRead = fread(buf, 1, sizeof(buf), f);
                [string appendFormat:@"%.*s", (int)charsRead, buf];
            }
            pclose(f);

            // Treat output as a filename to be loaded and contents returned.
            // NOTE: We do not retrieve the error as failure is not unexpected.
            NSString *path = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSData *data = [[NSData alloc] initWithContentsOfFile:path options:0 error:nil];
            if (data != nil) {
                content_ = data;
            } else {
                // No such file or file could not be read; treat output itself as content.
                content_ = [[string dataUsingEncoding:NSUTF8StringEncoding] retain];
            }
            [string release];
        }
    }
    return content_;
}

- (NSString *)mimeType {
    if (mimeType_ == nil) {
        const TSIncludeInstructionType includeType = [self includeType];
        if (includeType == TSIncludeInstructionTypePlist) {
            mimeType_ = @"application/x-plist";
        } else if (includeType == TSIncludeInstructionTypeFile) {
            mimeType_ = mimeTypeForExtension([[self filepath] pathExtension]);
        }

        if (mimeType_ == nil) {
            // Determine if content is text or binary.
            NSString *string = [[NSString alloc] initWithData:[self content] encoding:NSUTF8StringEncoding];
            mimeType_ = (string != nil) ? @"text/plain" : @"application/octet-stream";
            [string release];
        }

        // NOTE: For string literals, this is a no-op.
        [mimeType_ retain];
    }
    return mimeType_;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
