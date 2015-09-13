/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSEmailInstruction.h"

@interface TSInstruction (Private)
@property(nonatomic, copy) NSString *title;
@end

@implementation TSEmailInstruction

@synthesize ccAddresses = ccAddresses_;
@synthesize isSupport = isSupport_;
@synthesize toAddress = toAddress_;
@synthesize subject = subject_;

// NOTE: Format is:
//
//       email [as "<subject>"] to <email address> [cc <comma-separated email addresses>] [is_support]
//
- (instancetype)initWithTokens:(NSArray *)tokens {
    self = [super initWithTokens:tokens];
    if (self != nil) {
        enum {
            ModeAttribute,
            ModeCarbonCopies,
            ModeRecipient,
            ModeTitle
        } mode = ModeAttribute;

        for (NSString *token in tokens) {
            switch (mode) {
                case ModeAttribute:
                    if ([token isEqualToString:@"as"]) {
                        mode = ModeTitle;
                    } else if ([token isEqualToString:@"to"]) {
                        mode = ModeRecipient;
                    } else if ([token isEqualToString:@"cc"]) {
                        mode = ModeCarbonCopies;
                    } else if ([token isEqualToString:@"is_support"]) {
                        isSupport_ = YES;
                    }
                    break;
                case ModeCarbonCopies:
                    // FIXME: Add a proper check for email address validity.
                    if ([token rangeOfString:@"@"].location != NSNotFound) {
                        NSMutableArray *addresses = [[NSMutableArray alloc] init];

                        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t,"];
                        NSArray *components = [token componentsSeparatedByCharactersInSet:characterSet];
                        for (NSString *component in components) {
                            if ([component length] > 0) {
                                [addresses addObject:component];
                            }
                        }
                        ccAddresses_ = addresses;
                    }
                    mode = ModeAttribute;
                    break;
                case ModeRecipient:
                    // FIXME: Add a proper check for email address validity.
                    if ([token rangeOfString:@"@"].location != NSNotFound) {
                        toAddress_ = [token retain];
                    }
                    mode = ModeAttribute;
                    break;
                case ModeTitle:
                    subject_ = [stripQuotes(token) retain];
                    mode = ModeAttribute;
                    break;
                default:
                    break;
            }
        }

        if (subject_ == nil) {
            subject_ = [toAddress_ copy];
        }
        [self setTitle:NSLocalizedString(subject_, nil)];
    }
    return self;
}

- (void)dealloc {
    [toAddress_ release];
    [ccAddresses_ release];
    [subject_ release];
    [super dealloc];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
