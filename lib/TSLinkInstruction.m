/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSLinkInstruction.h"

static NSArray *recipientsFromString(NSString *string) {
    NSMutableArray *recipients = [NSMutableArray array];

    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t,"];
    NSArray *components = [string componentsSeparatedByCharactersInSet:characterSet];
    for (NSString *component in components) {
        if ([component length] > 0) {
            [recipients addObject:component];
        }
    }

    return recipients;
}

@interface TSInstruction (Private)
@property(nonatomic, copy) NSString *title;
@end

@implementation TSLinkInstruction

@synthesize recipients = recipients_;
@synthesize unlocalizedTitle = unlocalizedTitle_;
@synthesize url = url_;
@synthesize isEmail = isEmail_;
@synthesize isSupport = isSupport_;

// NOTE: Format is:
//
//       link [as "<title>"] [is_support] url <URL>
//       link [as "<title>"] [is_support] email <comma-separated email addresses>
//
- (instancetype)initWithTokens:(NSArray *)tokens {
    self = [super initWithTokens:tokens];
    if (self != nil) {
        enum {
            ModeAttribute,
            ModeRecipients,
            ModeTitle,
            ModeURL
        } mode = ModeAttribute;

        for (NSString *token in tokens) {
            switch (mode) {
                case ModeAttribute:
                    if ([token isEqualToString:@"as"]) {
                        mode = ModeTitle;
                    } else if ([token isEqualToString:@"email"]) {
                        isEmail_ = YES;
                        mode = ModeRecipients;
                    } else if ([token isEqualToString:@"is_support"]) {
                        isSupport_ = YES;
                    } else if ([token isEqualToString:@"url"]) {
                        mode = ModeURL;
                    }
                    break;
                case ModeRecipients:
                    // TODO: Consider adding a proper check for email addresses.
                    if ([token rangeOfString:@"@"].location != NSNotFound) {
                        recipients_ = [recipientsFromString(token) retain];
                    }
                    mode = ModeAttribute;
                    break;
                case ModeTitle:
                    unlocalizedTitle_ = [stripQuotes(token) retain];
                    mode = ModeAttribute;
                    break;
                case ModeURL:
                    url_ = [[NSURL alloc] initWithString:stripQuotes(token)];
                    mode = ModeAttribute;
                    break;
                default:
                    break;
            }
        }

        if (unlocalizedTitle_ == nil) {
            unlocalizedTitle_ = [(isEmail_ ? recipients_ : [url_ absoluteString]) copy];
        }
        [self setTitle:NSLocalizedString(unlocalizedTitle_, nil)];
    }
    return self;
}

- (void)dealloc {
    [recipients_ release];
    [unlocalizedTitle_ release];
    [url_ release];
    [super dealloc];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
