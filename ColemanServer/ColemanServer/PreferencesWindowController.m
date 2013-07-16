//
//  PreferencesWindowController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/5/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "DataStore.h"
#import "CertifcateStore.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

-(id)init
{
    self = [self initWithWindowNibName:NSStringFromClass(self.class)
                                 owner:self];
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // set button accordingly
    if ([CertifcateStore sharedStore].fileExists) {
        
        self.tlsButton.state = NSOnState;
        
    } else {
        
        self.tlsButton.state = NSOffState;
    }
    
}

#pragma mark

-(DataStore *)dataStore
{
    return [DataStore sharedStore];
}

-(CertifcateStore *)certificateStore
{
    return [CertifcateStore sharedStore];
}

#pragma mark

-(void)configureTLS:(NSButton *)sender {
    
    // on
    if (self.certificateStore.fileExists) {
        
        // remove certificate
        
        NSError *deleteError;
        
        [[NSFileManager defaultManager] removeItemAtPath:[CertifcateStore sharedStore].filePath
                                                   error:&deleteError];
        
        if (deleteError) {
            
            [NSApp presentError:deleteError
                 modalForWindow:self.window
                       delegate:nil
             didPresentSelector:nil
                    contextInfo:nil];
            
        }
        else {
            
            
            [[CertifcateStore sharedStore] checkIfCertificateIsSaved];
            
            self.tlsButton.state = NSOffState;
        }
        
    }
    // off
    else {
        
        // turn on...
        
        // find file and copy it
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.allowedFileTypes = @[@"crt"];
        openPanel.canChooseDirectories = NO;
        openPanel.allowsMultipleSelection = NO;
        
        [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
            
            if (result == NSOKButton) {
                
                // copy file in url to the app support path
                
                NSError *copyError;
                
                NSURL *fileUrl = [NSURL fileURLWithPath:[CertifcateStore sharedStore].filePath];
                
                [[NSFileManager defaultManager] copyItemAtURL:openPanel.URL
                                                        toURL:fileUrl
                                                        error:&copyError];
                
                if (copyError) {
                    
                    [NSApp presentError:copyError
                         modalForWindow:self.window
                               delegate:nil
                     didPresentSelector:nil
                            contextInfo:nil];
                    
                }
                else {
                    
                    [[CertifcateStore sharedStore] checkIfCertificateIsSaved];
                    
                    self.tlsButton.state = NSOnState;
                    
                }
                
            }
            
        }];
    }
}


@end
