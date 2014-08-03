/**
 * Name: Advanced Demo
 * Type: iOS app
 * Desc: iOS app to demonstrate use of TechSupport framework.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import "RootViewController.h"

#import <TechSupport/TechSupport.h>

#include "system_info.h"

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
    // Determine UDID of device.
    NSString *udid = uniqueDeviceIdentifier();

    // Request UDID-targetted instructions file from remote server.
    // TODO: Replace "myserver.com/" with your own server and path structure.
    // NOTE: Sample file contents:
    //
    //           include as \"IconState\" plist /var/mobile/Library/SpringBoard/IconState.plist
    //           include as \"Package List\" command /usr/bin/dpkg -l
    //
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://myserver.com/%@.txt", udid]];
    if (url != nil) {
        // NOTE: Performing synchronously for simplicity; should perform async in
        //       real application.
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if ((data != nil) && ([response statusCode] == 200)) {
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            [self generateWithInstructionLines:lines];
            [content release];
        } else {
            NSLog(@"ERROR: Failed to retrieve file: %@", [error localizedDescription]);
        }
    }
}

- (void)generateWithInstructionLines:(NSArray *)lines {
    // Create link instruction for email.
    // NOTE: This could also have been included in the remote file.
    TSLinkInstruction *linkInstruction = [TSLinkInstruction instructionWithString:@"link email developer@myserver.com is_support"];

    // Create an array of attachments.
    NSMutableArray *includeInstructions = [NSMutableArray new];
    for (NSString *line in lines) {
        TSIncludeInstruction *includeInstruction = [TSIncludeInstruction instructionWithString:line];
        if (includeInstruction != nil) {
            [includeInstructions addObject:includeInstruction];
        }
    }

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
