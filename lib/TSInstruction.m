/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSInstruction.h"

#import "TSIncludeInstruction.h"
#import "TSLinkInstruction.h"
#import "TSPackage.h"

static NSArray *tokenize(NSString *string) {
    NSMutableArray *result = [NSMutableArray array];

    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    NSCharacterSet *tabQuoteSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\""];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];

    BOOL inQuote = NO;
    NSString *token;
    while (![scanner isAtEnd]) {
        token = nil;
        if (inQuote) {
            // Scan and capture the quoted text.
            [scanner scanUpToString:@"\"" intoString:&token];
            token = [NSString stringWithFormat:@"\"%@\"", token];
            [scanner scanString:@"\"" intoString:NULL];
            inQuote = NO;
        } else {
            // Scan and capture the unquoted text, up to the next space/tab/quote.
            [scanner scanUpToCharactersFromSet:tabQuoteSet intoString:&token];
        }

        if (token != nil) {
            [result addObject:token];

            // Remove any whitespace between this and the next token.
            [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
            if ([scanner scanString:@"\"" intoString:NULL]) {
                inQuote = YES;
            }
        } else {
            break;
        }
    }

    return result;
}

static NSMutableDictionary *instructions$ = nil;

@implementation TSInstruction

@synthesize title = title_;
@synthesize tokens = tokens_;

+ (instancetype)instructionWithLine:(NSString *)line {
    if (instructions$ == nil) {
        instructions$ = [NSMutableDictionary new];
    }

    TSInstruction *instruction = [instructions$ objectForKey:line];
    if (instruction == nil) {
        NSArray *tokens = tokenize(line);
        NSUInteger count = [tokens count];
        if (count > 0) {
            Class klass = Nil;

            NSString *firstToken = [tokens objectAtIndex:0];
            if ([firstToken isEqualToString:@"include" ]) {
                klass = [TSIncludeInstruction class];
            } else if ([firstToken isEqualToString:@"link"]) {
                klass = [TSLinkInstruction class];
            }

            if (klass != Nil) {
                instruction = [[klass alloc] initWithTokens:tokens];
                if (instruction != nil) {
                    [instructions$ setObject:instruction forKey:line];
                    [instruction release];
                }
            }
        }
    }
    return instruction;
}

+ (void)flushInstructions {
    [instructions$ release];
    instructions$ = nil;
}

- (instancetype)initWithTokens:(NSArray *)tokens {
    self = [super init];
    if (self != nil) {
        tokens_ = [tokens copy];
    }
    return self;
}

- (void)dealloc {
    [title_ release];
    [tokens_ release];
    [super dealloc];
}

- (NSComparisonResult)compare:(TSInstruction *)instruction {
    Class thisClass = [self class];
    Class thatClass = [instruction class];
    if (thisClass == thatClass) {
        return [[self title] compare:[instruction title]];
    } else {
        return (thisClass == [TSLinkInstruction class]) ? NSOrderedAscending : NSOrderedDescending;
    }
}

- (UITableViewCell *)format:(UITableViewCell *)cell {
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"."] autorelease];
    }

    UILabel *textLabel = cell.textLabel;
    textLabel.text = [self title];
    textLabel.textColor = [UIColor blackColor];

    UILabel *detailTextLabel = cell.detailTextLabel;
    detailTextLabel.font = [UIFont systemFontOfSize:9.0];
    detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    detailTextLabel.numberOfLines = 2;

    return cell;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
