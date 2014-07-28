/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSHTMLViewController.h"

@interface UIWebDocumentView : UIView
- (id)text;
@end

@interface UIWebView ()
- (UIWebDocumentView *)_documentView;
@end

static NSString *escapedHTMLString(NSString *string) {
    const NSUInteger length = [string length];
    if (length == 0) {
        return string;
    }

    NSMutableString *escapedString = [NSMutableString string];
    NSRange range = (NSRange){0, 0};

    for (NSUInteger i = 0; i < length; ++i) {
        NSString *code = nil;

        char c = [string characterAtIndex:i];
        switch (c) {
            case '\"': code = @"&quot;"; break;
            case '\'': code = @"&#x27;"; break;
            case '<': code = @"&lt;"; break;
            case '>': code = @"&gt;"; break;
            case '&': code = @"&amp;"; break;
            default: break;
        }

        if (code == nil) {
            range.length += 1;
        } else {
            if (range.length > 0) {
                [escapedString appendString:[string substringWithRange:range]];
            }
            [escapedString appendString:code];

            range.location = i + 1;
            range.length = 0;
        }
    }

    // Append remainder of string.
    [escapedString appendString:[string substringWithRange:range]];

    return escapedString;
}

@implementation TSHTMLViewController {
    NSString *content_;
    UIWebView *webView_;
}

- (id)initWithHTMLContent:(NSString *)content {
    return [self initWithHTMLContent:content dataDetector:UIDataDetectorTypeNone];
}

- (id)initWithHTMLContent:(NSString *)content dataDetector:(UIDataDetectorTypes)dataDetectors {
    self = [super init];
    if (self != nil) {
        content_ = [[NSString alloc] initWithFormat:
            @"<html><head><title>.</title></head><body><pre style=\"font-size:8pt;\">%@</pre></body></html>",
            escapedHTMLString(content)];

        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
        webView.scrollView.bounces = NO;
        webView.dataDetectorTypes = dataDetectors;
        webView_ = webView;
    }
    return self;
}

- (void)dealloc {
    [content_ release];
    [webView_ release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)loadView {
    self.view = webView_;

    NSString *title = NSLocalizedString(@"COPY", nil);
    UIBarButtonItem *copyButton = [[UIBarButtonItem alloc] initWithTitle:title
        style:UIBarButtonItemStyleBordered target:self action:@selector(copyTextContent)];
    self.navigationItem.rightBarButtonItem = copyButton;
    [copyButton release];
}

- (void)viewWillAppear:(BOOL)animated {
    [webView_ loadHTMLString:content_ baseURL:nil];
}

#pragma mark - Actions

- (void)copyTextContent {
    UIWebDocumentView *webDocView = [webView_ _documentView];
    [webDocView becomeFirstResponder];
    [UIPasteboard generalPasteboard].string = [webDocView text];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
