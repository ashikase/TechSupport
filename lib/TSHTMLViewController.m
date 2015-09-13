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
- (UIScrollView *)_scrollView;
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
    UIWebView *webView_;

    NSString *content_;
    UIDataDetectorTypes dataDetectors_;
}

@synthesize webView = webView_;

- (id)initWithHTMLContent:(NSString *)content {
    return [self initWithHTMLContent:content dataDetector:UIDataDetectorTypeNone];
}

- (id)initWithHTMLContent:(NSString *)content dataDetector:(UIDataDetectorTypes)dataDetectors {
    self = [super init];
    if (self != nil) {
        [self setContent:content];
        dataDetectors_ = dataDetectors;

        NSString *title = NSLocalizedString(@"COPY", nil);
        UIBarButtonItem *copyButton = [[UIBarButtonItem alloc] initWithTitle:title
            style:UIBarButtonItemStyleBordered target:self action:@selector(copyTextContent)];
        self.navigationItem.rightBarButtonItem = copyButton;
        [copyButton release];
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
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGRect screenBounds = [mainScreen bounds];
    CGRect rect = CGRectMake(0.0, 0.0, screenBounds.size.width, screenBounds.size.height);

    UIWebView *webView = [[UIWebView alloc] initWithFrame:rect];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.dataDetectorTypes = dataDetectors_;
    webView.scalesPageToFit = YES;
    if (IOS_LT(5_0)) {
        [[webView _scrollView] setBounces:NO];
    } else {
        [[webView scrollView] setBounces:NO];
    }
    [webView loadHTMLString:content_ baseURL:nil];
    webView_ = webView;

    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview:webView_];
    self.view = view;
}


#pragma mark - Actions

- (void)copyTextContent {
    UIWebDocumentView *webDocView = [webView_ _documentView];
    [webDocView becomeFirstResponder];
    [UIPasteboard generalPasteboard].string = [webDocView text];
}

#pragma mark - Other

- (void)setContent:(NSString *)content {
    [content_ release];
    content_ = [[NSString alloc] initWithFormat:
        @"<html><head><title>.</title><meta name='viewport' content='initial-scale=1.0,maximum-scale=3.0'/></head><body><pre style=\"font-size:8pt;\">%@</pre></body></html>",
        escapedHTMLString(content)];

    if ([self isViewLoaded]) {
        [webView_ loadHTMLString:content_ baseURL:nil];
    }
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
