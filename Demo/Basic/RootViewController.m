/**
 * Name: Basic Demo
 * Type: iOS app
 * Desc: iOS app to demonstrate use of TechSupport framework.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import "RootViewController.h"

#import <TechSupport/TechSupport.h>

@implementation RootViewController

- (void)loadView {
    // Create a simple screen with a button for calling the TechSupport code.
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIView *view = [[UIView alloc] initWithFrame:screenBounds];
    view.backgroundColor = [UIColor whiteColor];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [button setFrame:CGRectMake(10.0, 0.5 * (screenBounds.size.height - 44.0), screenBounds.size.width - 20.0, 44.0)];
    [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Report Issue" forState:UIControlStateNormal];
    [[button titleLabel] setFont:[UIFont boldSystemFontOfSize:18.0]];
    [view addSubview:button];

    CALayer *layer = [button layer];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [layer setBorderWidth:1.0];
    [layer setCornerRadius:8.0];
    [layer setMasksToBounds:YES];

    [self setView:view];
    [view release];
}

- (void)buttonTapped {
    // Load package to report on.
    TSPackage *package = [TSPackage packageWithIdentifier:@"jp.ashikase.techsupport"];

    // Create link instruction for email.
    TSLinkInstruction *linkInstruction = [TSLinkInstruction instructionWithString:@"link email developer@myserver.com is_support"];

    // Create an array of attachments.
    NSMutableArray *includeInstructions = [NSMutableArray new];

    // Include a file.
    [includeInstructions addObject:[TSIncludeInstruction instructionWithString:@"include as \"IconState\" plist /var/mobile/Library/SpringBoard/IconState.plist"]];

    // Include preferences file (if it exists for the given package).
    TSIncludeInstruction *includeInstruction = [package preferencesAttachment];
    if (includeInstruction != nil) {
        [includeInstructions addObject:includeInstruction];
    }

    // Include the output of a command.
    [includeInstructions addObject:[TSIncludeInstruction instructionWithString:@"include as \"Package List\" command /usr/bin/dpkg -l"]];

    // Create and present contact controller.
    TSContactViewController *controller = [[TSContactViewController alloc] initWithPackage:nil linkInstruction:linkInstruction includeInstructions:includeInstructions];
    [controller setTitle:@"Contact Form"];
    [[self navigationController] pushViewController:controller animated:YES];
    [controller setMessageBody:@"This is the body of the message."];
    [controller setRequiresDetailsFromUser:YES];
    [controller release];
    [includeInstructions release];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
