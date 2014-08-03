/**
 * Name: Basic Demo
 * Type: iOS app
 * Desc: iOS app to demonstrate use of TechSupport framework.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import "ApplicationDelegate.h"

#import "RootViewController.h"

@implementation ApplicationDelegate {
    UINavigationController *navController_;
    UIWindow *window_;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    RootViewController *viewController = [RootViewController new];
    UINavigationController *navController = [UINavigationController new];
    [navController pushViewController:viewController animated:NO];
    [viewController release];

    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [window setRootViewController:navController];
    [window makeKeyAndVisible];

    navController_ = navController;
    window_ = window;
}

- (void)dealloc {
    [navController_ release];
    [window_ release];
    [super dealloc];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
