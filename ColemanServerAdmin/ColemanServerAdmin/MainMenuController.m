//
//  MainMenuController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "MainMenuController.h"
#import "APIStore.h"
#import "EntriesWindowController.h"
#import "AppDelegate.h"

@implementation MainMenuController

-(id)init
{
    self = [super init];
    if (self) {
        
        
    }
    return self;
}

- (IBAction)connect:(id)sender {
        
    // get values
    NSString *username = self.usernameTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;
    NSString *urlString = self.urlTextField.stringValue;
    
    [APIStore sharedStore].baseURL = urlString;
    
    [[APIStore sharedStore] loginWithUsername:username password:password completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error];
                
            }
            else {
                
                [self showEntriesWC];
                
            }
        }];
        
    }];
}

#pragma mark - Commands

-(IBAction)signOut:(id)sender
{
    // show login window
    AppDelegate *appDelegate = [NSApp delegate];
    [appDelegate.window makeKeyAndOrderFront:nil];
    
    // close entries window
    _entriesWC = nil;
    
    // reset API Store
    [[APIStore sharedStore] init];
    
}

#pragma mark - First Responder

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(signOut:)) {
        
        if (!_entriesWC) {
            return NO;
        }
        
    }
    
    return YES;
    
}

-(void)showEntriesWC
{
    // open entries window controller
    _entriesWC = [[EntriesWindowController alloc] init];
    
    AppDelegate *appDelegate = [NSApp delegate];
    [appDelegate.window close];
    
    [_entriesWC showWindow:nil];
}


@end
