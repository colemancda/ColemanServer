//
//  MenuController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/4/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "MenuController.h"
#import "PreferencesWindowController.h"
#import "AppDelegate.h"
#import "DataStore.h"
#import "LogStore.h"

@implementation MenuController

-(void)preferences:(id)sender
{
    // open preferences window
    if (!_preferencesWC) {
        _preferencesWC = [[PreferencesWindowController alloc] init];
    }
    
    [_preferencesWC showWindow:sender];
}

-(void)save:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    [savePanel beginSheetModalForWindow:appDelegate.window completionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            
            // get the url
            NSURL *url = savePanel.URL;
            
            // save the Data Store
            BOOL savedCorrectly = [[DataStore sharedStore] save];
            
            if (!savedCorrectly) {
                
                NSError *saveError = [NSError errorWithDomain:kErrorDomain
                                                         code:1000
                                                     userInfo:@{NSLocalizedDescriptionKey:
                                      NSLocalizedString(@"Could not save the Data Store to disk",
                                                        @"Could not save the Data Store to disk")}];
                
                [NSApp presentError:saveError];
                
                // close panel
                [savePanel orderOut:self];
                
                return;
                
            }
            
            // make copy
            NSData *data = [NSData dataWithContentsOfFile:[DataStore sharedStore].archivePath];
            
            // save data to URL
            [data writeToURL:url
                  atomically:YES];
            
            // close panel
            [savePanel orderOut:self];
        }
        
    }];
}

-(void)openLogs:(id)sender
{
    // get Log folder URL
    NSString *urlString = [LogStore sharedStore].defaultArchivePath;
    urlString = urlString.stringByDeletingLastPathComponent;
    NSURL *url = [NSURL fileURLWithPath:urlString];
    
    // open it 
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
