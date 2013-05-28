//
//  AppDelegate.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "PageViewController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
        
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    
    _rootVC = loginVC;
    
    [self.pageController navigateForwardToObject:_rootVC];
    
    self.box.contentView = _rootVC.view;
    
    [self.rootVC viewDidLoad];
    
    [self.rootVC viewDidAppear];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#pragma mark - Page Controller Delegate

-(void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    // set the content view of the box
    PageViewController *vc = (PageViewController *)object;
    self.box.contentView = vc.view;
    
    [vc viewDidAppear];
}

-(void)pageControllerWillStartLiveTransition:(NSPageController *)pageController
{
    
    
}

-(void)pageControllerDidEndLiveTransition:(NSPageController *)pageController
{
    [pageController completeTransition];
}


#pragma mark - Dynamic Strings

+(NSString *)bundleID
{
    static NSString *bundleID = nil;
    
    if (!bundleID) {
        
        bundleID = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
        
    }
    
    return bundleID;
    
}

+(NSString *)errorDomain
{
    static NSString *errorDomain = nil;
    
    if (!errorDomain) {
        
        errorDomain = [[[self class] bundleID] stringByAppendingPathExtension:@"ErrorDomain"];
        
    }
    
    return errorDomain;
}


@end
