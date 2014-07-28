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

@class LinkInstruction;
@class Package;

@interface ContactViewController : UIViewController
- (id)initWithPackage:(Package *)package suspect:(NSString *)suspect linkInstruction:(LinkInstruction *)linkInstruction includeInstructions:(NSArray *)includeInstructions;
@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
