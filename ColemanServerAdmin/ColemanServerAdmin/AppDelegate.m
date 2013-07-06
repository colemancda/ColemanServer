//
//  AppDelegate.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "APIStore.h"

static NSString *kRootVCKeyPath = @"rootViewController";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // KVO RootVC
    [self addObserver:self
           forKeyPath:kRootVCKeyPath
              options:NSKeyValueObservingOptionOld
              context:nil];
    
    [self signOut];
    
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

-(void)dealloc
{
    // KVO
    [self removeObserver:self
              forKeyPath:kRootVCKeyPath];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:kRootVCKeyPath]) {
        
        // set the content view of the box
        self.box.contentView = self.rootViewController.view;
        
    }
    
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

#pragma mark

-(void)signOut
{
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    
    self.rootViewController = loginVC;
    
    [[APIStore sharedStore] terminateSession];
}


@end
