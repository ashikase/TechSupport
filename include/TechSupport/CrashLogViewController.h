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

@class IncludeInstruction;

@interface CrashLogViewController : UIViewController
@property(nonatomic, retain) IncludeInstruction *instruction;
+ (void)escapeHTML:(NSMutableString *)string;
- (void)setHTMLContent:(NSString *)content withDataDetector:(UIDataDetectorTypes)dataDetectors;
@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
