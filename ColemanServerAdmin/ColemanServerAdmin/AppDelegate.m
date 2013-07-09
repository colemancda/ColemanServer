//
//  AppDelegate.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "AppDelegate.h"
#import "APIStore.h"
#import "MainMenuController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // KVC token
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:@"self.token"
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
    // try to get token from preferences
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    
    if (token) {
        
        NSLog(@"Logging in using saved token...");
        
        // connect using saved token
        NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
        
        [APIStore sharedStore].baseURL = urlString;
        [APIStore sharedStore].token = token;
        
        [_mainMenuController showEntriesWC];
    }
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
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

#pragma mark - KVC

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"self.token"] && object == [APIStore sharedStore]) {
        
        // save token in preferences
        [[NSUserDefaults standardUserDefaults] setObject:[APIStore sharedStore].token forKey:@"token"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
}


@end
