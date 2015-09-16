/**
 * Name: TechSupport
 * Type: iOS framework
 * Desc: iOS framework to assist in providing support for and receiving issue
 *       reports and feedback from users.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "TSContactViewController.h"

#import <MessageUI/MessageUI.h>
#import "TSHTMLViewController.h"
//#import "ModalActionSheet.h"
//#import "pastie.h"

#import "TSEmailInstruction.h"
#import "TSIncludeInstruction.h"
#import "TSLinkInstruction.h"
#import "TSPackage.h"

#include "system_info.h"

static const CGFloat kTableRowHeight = 48.0;

@interface UIColor ()
+ (id)tableCellBlueTextColor;
@end

@interface TSContactViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>
@end

@implementation TSContactViewController {
    UITextView *textView_;
    UITableView *tableView_;
    BOOL hasShownIntroduction_;

    NSString *defaultPlaceholderText_;

    TSPackage *package_;
    NSArray *instructions_;
    TSInstruction *recipientInstruction_;
    NSArray *includeInstructions_;
}

@synthesize detailEntryPlaceholderText = detailEntryPlaceholderText_;
@synthesize subject = subject_;
@synthesize messageBody = messageBody_;
@synthesize detailFormat = detailFormat_;
@synthesize byline = byline_;
@synthesize requiresDetailsFromUser = requiresDetailsFromUser_;

#pragma mark - Creation & Destruction

static void init(TSContactViewController *self) {
    self->defaultPlaceholderText_ = [NSLocalizedString(@"EMAIL_PLACEHOLDER", nil) retain];

    UIBarButtonItem *buttonItem;
    NSString *title;

    title = NSLocalizedString(@"CANCEL", nil);
    buttonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonTapped)];
    self.navigationItem.leftBarButtonItem = buttonItem;
    [buttonItem release];

    title = NSLocalizedString(@"SUBMIT", nil);
    buttonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(submitButtonTapped)];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [buttonItem release];
}

- (id)initWithPackage:(TSPackage *)package linkInstruction:(TSLinkInstruction *)linkInstruction includeInstructions:(NSArray *)includeInstructions {
    self = [super init];
    if (self != nil) {
        package_ = [package retain];
        recipientInstruction_ = [linkInstruction retain];
        includeInstructions_ = [includeInstructions copy];

        init(self);
    }
    return self;
}

- (id)initWithPackage:(TSPackage *)package instructions:(NSArray *)instructions {
    self = [super init];
    if (self != nil) {
        package_ = [package retain];

        NSMutableArray *includeInstructions = [[NSMutableArray alloc] init];
        TSInstruction *recipientInstruction = nil;
        for (TSInstruction *instruction in instructions) {
            if ([instruction isKindOfClass:[TSIncludeInstruction class]]) {
                [includeInstructions addObject:instruction];
            } else {
                recipientInstruction = instruction;
            }
        }
        includeInstructions_ = includeInstructions;
        recipientInstruction_ = [recipientInstruction retain];

        init(self);
    }
    return self;
}

- (void)dealloc {
    [textView_ release];
    [tableView_ release];

    [defaultPlaceholderText_ release];
    [detailEntryPlaceholderText_ release];
    [subject_ release];
    [messageBody_ release];
    [detailFormat_ release];
    [byline_ release];

    [package_ release];
    [recipientInstruction_ release];
    [includeInstructions_ release];

    [super dealloc];
}

- (void)loadView {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    const CGFloat sectionHeaderHeight = 23.0;
    CGFloat tableViewHeight = sectionHeaderHeight + kTableRowHeight * MIN(4.0, [includeInstructions_ count]);
    CGFloat textViewHeight = (screenBounds.size.height - tableViewHeight);

    // Create a text view to enter crash details.
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 0.0, screenBounds.size.width, textViewHeight)];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.delegate = self;
    textView.font = [UIFont systemFontOfSize:18.0];
    textView.text = [self detailEntryPlaceholderText];
    textView.textColor = [UIColor lightGrayColor];
    textView_ = textView;

    // Add a toolbar to dismiss the keyboard.
    if (IOS_GTE(3_2)) {
        UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
        NSArray *items = [[NSArray alloc] initWithObjects:spaceItem, doneItem, nil];
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, screenBounds.size.width, 44.0)];
        toolbar.items = items;
        [toolbar sizeToFit];
        [items release];
        [doneItem release];
        [spaceItem release];
        textView_.inputAccessoryView = toolbar;
        [toolbar release];
    }

    // Create a table view to show attachments.
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, textViewHeight, screenBounds.size.width, tableViewHeight)];
    tableView.allowsSelectionDuringEditing = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.editing = YES;
    tableView_ = tableView;

    // Create a container view to hold all other views.
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, screenBounds.size.width, screenBounds.size.height)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview:textView];
    [view addSubview:tableView];
    self.view = view;
    [view release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)viewDidAppear:(BOOL)animated {
    if (!hasShownIntroduction_) {
        NSString *title = NSLocalizedString(@"CONTACT_INTRO_TITLE", nil);
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"CONTACT_INTRO_MESSAGE", nil),
            NSLocalizedString(@"SUBMIT", nil), NSLocalizedString(@"CANCEL", nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
            cancelButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alertView show];
        [alertView release];

        hasShownIntroduction_ = YES;
    }
}

#pragma mark - Other

- (NSString *)messageBodyWithDetails {
    NSMutableString *string = [NSMutableString string];

    // Add device information.
    UIDevice *device = [UIDevice currentDevice];
    [string appendFormat:@"%@ %@: %@\n\n", platformVersion(), [device systemVersion], uniqueDeviceIdentifier()];

    // Add message body.
    NSString *messageBody = [self messageBody];
    if ([messageBody length] > 0) {
        [string appendString:messageBody];
        [string appendString:@"\n\n"];
    }

    // Add details from user.
    NSString *text = [textView_ text];
    if (![text isEqualToString:[self detailEntryPlaceholderText]]) {
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        text = [text stringByTrimmingCharactersInSet:characterSet];

        NSString *detailFormat = [self detailFormat];
        if (detailFormat != nil) {
            [string appendFormat:detailFormat, text];
        } else {
            [string appendString:text];
        }
    }

    // Add byline.
    NSString *byline = [self byline];
    if (byline != nil) {
        [string appendString:@"\n\n"];
        [string appendString:byline];
    }

    return string;
}

- (NSArray *)selectedAttachments {
    // Determine selected attachments.
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *indexPath in [tableView_ indexPathsForSelectedRows]) {
        [indexSet addIndex:indexPath.row];
    }
    return [includeInstructions_ objectsAtIndexes:indexSet];
}

- (NSString *)uploadAttachments {
    NSMutableString *urlsString = nil;

#if 0
    ModalActionSheet *hud = [ModalActionSheet new];
    [hud show];

    // FIXME: The "content" property now returns NSData, not NSString.
    NSArray *contents = [[self selectedAttachments] valueForKey:@"content"];
    if ([contents count] > 0) {
        NSArray *urls = pastie(contents, hud);
        if (urls != nil) {
            urlsString = [NSMutableString string];
            for (NSURL *url in urls) {
                [urlsString appendString:[url absoluteString]];
                [urlsString appendString:@"\n"];
            }
        } else {
            NSString *title = NSLocalizedString(@"Upload failed", nil);
            NSString *message = NSLocalizedString(@"pastie.org is unreachable.", nil);
            NSString *cancel = NSLocalizedString(@"OK", nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
                cancelButtonTitle:cancel otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }

    [hud hide];
    [hud release];
#endif

    return urlsString;
}

#pragma mark - Properties

- (NSString *)detailEntryPlaceholderText {
    return detailEntryPlaceholderText_ ?: defaultPlaceholderText_;
}

#pragma mark - Actions (UIBarButtonItem)

- (void)cancelButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonTapped {
     [textView_ resignFirstResponder];
}

- (void)submitButtonTapped {
    if ([recipientInstruction_ isKindOfClass:[TSEmailInstruction class]] || [(TSLinkInstruction *)recipientInstruction_ isEmail]) {
        NSString *title = NSLocalizedString(@"SUBMIT_EMAIL_TITLE", nil);
        NSString *message = NSLocalizedString(@"SUBMIT_EMAIL_MESSAGE", nil);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self
            cancelButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alertView show];
        [alertView release];
    } else {
        [self submit];
    }
}

#pragma mark - Other

- (void)submit {
    NSString *okMessage = NSLocalizedString(@"OK", nil);

    NSString *detailText = textView_.text;
    if ([self requiresDetailsFromUser] && ([detailText isEqualToString:@""] || [detailText isEqualToString:[self detailEntryPlaceholderText]])) {
        NSString *detailRequiredTitle = NSLocalizedString(@"DETAIL_REQUIRED_TITLE", nil);
        NSString *detailRequiredMessage = NSLocalizedString(@"DETAIL_REQUIRED_MESSAGE", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:detailRequiredTitle message:detailRequiredMessage
            delegate:nil cancelButtonTitle:okMessage otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }

    if ([recipientInstruction_ isKindOfClass:[TSEmailInstruction class]] || [(TSLinkInstruction *)recipientInstruction_ isEmail]) {
        if ([MFMailComposeViewController canSendMail]) {
            // Setup mail controller.
            MFMailComposeViewController *controller = [MFMailComposeViewController new];
            [controller setMailComposeDelegate:self];
            [controller setMessageBody:[self messageBodyWithDetails] isHTML:NO];

            NSString *subject = nil;
            if ([recipientInstruction_ isKindOfClass:[TSEmailInstruction class]]) {
                subject = [(TSEmailInstruction *)recipientInstruction_ subject];
            }
            if (subject == nil) {
                subject = [self subject];
            }
            [controller setSubject:subject];

            NSArray *recipients = nil;
            if ([recipientInstruction_ isKindOfClass:[TSEmailInstruction class]]) {
                recipients = [NSArray arrayWithObject:[(TSEmailInstruction *)recipientInstruction_ toAddress]];
            } else {
                recipients = [(TSLinkInstruction *)recipientInstruction_ recipients];
            }
            [controller setToRecipients:recipients];

            // Add attachments.
            for (TSIncludeInstruction *instruction in [self selectedAttachments]) {
                // Attach to the email.
                NSData *data = [instruction content];
                if (data != nil) {
                    TSIncludeInstructionType includeType = [instruction includeType];
                    NSString *filepath = [instruction filepath];
                    NSString *filename = (includeType == TSIncludeInstructionTypeCommand) ?
                        [[instruction title] stringByAppendingPathExtension:@"txt"] : [filepath lastPathComponent];
                    NSString *mimeType = [instruction mimeType];
                    [controller addAttachmentData:data mimeType:mimeType fileName:filename];
                }
            }

            // Present the mail controller for confirmation.
            if (IOS_LT(6_0)) {
                [self presentModalViewController:controller animated:YES];
            } else {
                [self presentViewController:controller animated:YES completion:nil];
            }
            [controller release];
        } else {
            NSString *cannotMailMessage = NSLocalizedString(@"CANNOT_EMAIL", nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:cannotMailMessage message:nil delegate:nil cancelButtonTitle:okMessage otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    } else {
        // Upload attachments to paste site and open support link.
        NSString *urlsString = [self uploadAttachments];
        if (urlsString != nil) {
            NSMutableString *string = [detailText mutableCopy];
            [string appendString:@"\n"];
            [string appendString:urlsString];
            [UIPasteboard generalPasteboard].string = string;
            [[UIApplication sharedApplication] openURL:[(TSLinkInstruction *)recipientInstruction_ url]];
            [string release];
        }
    }
}

#pragma mark - Delegate (MFMailComposeViewControllerDelegate)

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Display error on failure.
    if (result == MFMailComposeResultFailed) {
        NSString *message = [NSLocalizedString(@"EMAIL_FAILED_1", nil) stringByAppendingString:[error localizedDescription]];
        NSString *okMessage = NSLocalizedString(@"OK", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil
            cancelButtonTitle:okMessage otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

    // Dismiss mail controller and optionally return to previous controller.
    if (IOS_LT(6_0)) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        if ((result == MFMailComposeResultCancelled) || (result == MFMailComposeResultFailed)) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }
}

#pragma mark - Delegate (UIAlertViewDelegate)

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self submit];
}

#pragma mark - Delegate (UITableViewDataSource)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [includeInstructions_ count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"ATTACHMENTS", nil);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Returning "3" enables multiple cell selection.
    // NOTE: Versions of iOS prior to 5.0 supported multiple cell
    //       selection, but only via the private API.
    // FIXME: As this is private, this might change in a future release.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"."];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"."] autorelease];
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.indentationWidth = 0.0;

        cell.textLabel.textColor = [UIColor blackColor];

        UILabel *detailTextLabel = cell.detailTextLabel;
        detailTextLabel.font = [UIFont systemFontOfSize:9.0];
        detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        detailTextLabel.numberOfLines = 2;
    }

    TSIncludeInstruction *instruction = [includeInstructions_ objectAtIndex:indexPath.row];
    cell.textLabel.text = [instruction title];
    if ([instruction includeType] == TSIncludeInstructionTypeCommand) {
        NSString *command = [instruction command];
        NSRange range = [command rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
        cell.detailTextLabel.text = (range.location == NSNotFound) ? command : @"<multiline command>";
    } else {
        cell.detailTextLabel.text = [instruction filepath];
    }

    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    return cell;
}

#pragma mark - Delegate (UITableViewDelegate)

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    TSIncludeInstruction *instruction = [includeInstructions_ objectAtIndex:indexPath.row];
    NSString *content = [[NSString alloc] initWithData:[instruction content] encoding:NSUTF8StringEncoding];
    if (content != nil) {
        TSHTMLViewController *controller = [[TSHTMLViewController alloc] initWithHTMLContent:content];
        controller.title = [instruction title] ?: NSLocalizedString(@"INCLUDE_UNTITLED", nil);
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
        [content release];
    } else {
        // TODO: Consider adding a link to "View with iFile".
        NSString *message = NSLocalizedString(@"NOT_TEXT_MESSAGE", nil);
        NSString *okTitle = NSLocalizedString(@"OK", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil
            cancelButtonTitle:okTitle otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NOTE: Setting "rowHeight" in loadView would be more efficient, but for
    //       some reason it had no effect (tested with iOS 7.1.2).
    return kTableRowHeight;
}

#pragma mark - Delegate (UITextViewDelegate)

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:[self detailEntryPlaceholderText]]) {
         textView.text = @"";
         textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = [self detailEntryPlaceholderText];
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
