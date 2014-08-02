/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import <UIKit/UIKit.h>

@class TSLinkInstruction;
@class TSPackage;

@interface TSContactViewController : UIViewController

/**
 * The string that is displayed when there is not input from the user.
 *
 * This value is _nil_ by default. When nil, a default placeholder string will
 * be displayed. The default string is localized.
 */
@property(nonatomic, copy) NSString *detailEntryPlaceholderText;

/**
 * The string displayed in the generated email, below the device details and
 * above the user-entered details.
 *
 * This value is _nil_ by default.
 */
@property(nonatomic, copy) NSString *messageBody;

/**
 * Initializer.
 *
 * @param package The package to generate an email for.
 * @param linkInstruction The instruction containing the email command.
 * @param includeInstructions Array of TSIncludeInstruction objects specifying
 *        what to attach to the generated email.
 *
 * @return A new TSContactViewController instance.
 */
- (id)initWithPackage:(TSPackage *)package linkInstruction:(TSLinkInstruction *)linkInstruction includeInstructions:(NSArray *)includeInstructions;

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
