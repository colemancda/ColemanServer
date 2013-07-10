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
    [APIStore sharedStore].username = username;
    
    [[APIStore sharedStore] loginWithPassword:password completion:^(NSError *error) {
        
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
    // close entries window
    _entriesWC = nil;
    
    // show login window
    AppDelegate *appDelegate = [NSApp delegate];
    [appDelegate.window makeKeyAndOrderFront:nil];
    [appDelegate.window setFrame:_oldRect
                         display:YES
                         animate:NO];
    
    // reset API Store
    [[APIStore sharedStore] reset];
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
    
    _oldRect = appDelegate.window.frame;
    NSRect newRect = NSRectFromCGRect(CGRectMake(_oldRect.origin.x,
                                                 -_oldRect.size.height,
                                                 _oldRect.size.width,
                                                 _oldRect.size.height));
    [appDelegate.window setFrame:newRect
                         display:YES
                         animate:YES];
    
    [appDelegate.window close];
    
    [_entriesWC showWindow:nil];
}

@end
