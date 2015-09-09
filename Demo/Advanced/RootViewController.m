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

//#define BASE_URL_STRING @"http://myserver.com"
#ifndef BASE_URL_STRING
#error "Must define BASE_URL_STRING using your own server in order to use this demo."
#endif

@interface RootViewController () <NSURLConnectionDelegate>
@end

@implementation RootViewController {
    NSURLConnection *connection_;
    NSMutableData *data_;
}

- (void)dealloc {
    [connection_ release];
    [data_ release];
    [super dealloc];
}

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
    if (connection_ == nil) {
        // Determine UDID of device.
        NSString *udid = uniqueDeviceIdentifier();

        // Request UDID-targetted instructions file from remote server.
        // TODO: Replace "myserver.com/" with your own server and path structure.
        // NOTE: Sample file contents:
        //
        //           include as \"IconState\" plist /var/mobile/Library/SpringBoard/IconState.plist
        //           include as \"Package List\" command /usr/bin/dpkg -l
        //
        NSString *urlString = [BASE_URL_STRING stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.txt", udid]];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url != nil) {
            // NOTE: Performing synchronously for simplicity; should perform async in
            //       real application.
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
            [request release];
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

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (statusCode == 200) {
        data_ = [[NSMutableData alloc] init];
    } else {
        // NOTE: Only a warning as the response may be a redirect (which
        //       would lead to this delegate method getting called again).
        NSLog(@"WARNING: Received response: %@", response);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (data_ != nil) {
        [data_ appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (data_ != nil) {
        NSString *content = [[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding];
        if (content != nil) {
            NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            [self generateWithInstructionLines:lines];
            [content release];
        } else {
            NSLog(@"ERROR: Unable to interpret downloaded content as a UTF8 string.");
        }

        [data_ release];
        data_ = nil;
        [connection_ release];
        connection_ = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
     NSLog(@"ERROR: Connection failed: %@ %@",
        [error localizedDescription],
        [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    [data_ release];
    data_ = nil;
    [connection_ release];
    connection_ = nil;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
