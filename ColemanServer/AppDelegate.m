//
//  AppDelegate.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/2/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "LogStore.h"
#import "ServerStore.h"
#import "MainViewController.h"

static NSString *kRootVCKeyPath = @"rootViewController";

NSString *const kErrorDomain = @"com.ColemanCDA.ColemanServer.ErrorDomain";

const NSInteger kErrorCodeServerLaunch = 101;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // log the app start
    [[LogStore sharedStore] addEntry:@"App launched"];
    
    // try to start the server...
    
    // get the default port
    NSNumber *defaultPort = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DefaultPort"];
    
    // start server
    [[ServerStore sharedStore] startServerWithPort:defaultPort.unsignedIntegerValue];
    
    // KVO RootVC
    [self addObserver:self
           forKeyPath:kRootVCKeyPath
              options:NSKeyValueObservingOptionOld
              context:nil];
    
    // load the main VC
    MainViewController *mainVC = [[MainViewController alloc] init];
    self.rootViewController = mainVC;
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

#pragma mark

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                   hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:self];
    
    return YES;
}

@end
