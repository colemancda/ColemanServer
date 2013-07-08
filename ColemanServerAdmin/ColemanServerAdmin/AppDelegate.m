//
//  AppDelegate.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "AppDelegate.h"
#import "APIStore.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    
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


@end
