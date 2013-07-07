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
                
                // fetch number of entries
                [[APIStore sharedStore] fetchNumberOfEntriesWithCompletion:^(NSError *error) {
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                       
                        if (error) {
                            [NSApp presentError:error];
                        }
                        
                        else {
                            
                            // download every entry
                            NSInteger count = [APIStore sharedStore].numberOfEntries.integerValue;
                            __block NSError *previousError;
                            for (int i = 0; i < count; i++) {
                                
                                [[APIStore sharedStore] fetchEntry:i completion:^(NSError *fetchError) {
                                    
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        
                                        if (previousError) {
                                            
                                            return;
                                        }
                                        
                                        if (fetchError) {
                                            
                                            previousError = fetchError;
                                            
                                            [NSApp presentError:fetchError];
                                            
                                            return;
                                        }
                                        
                                        // if last entry downloaded successfully
                                        if (i == count - 1) {
                                            
                                            // open entries window controller
                                            if (!_entriesWC) {
                                                _entriesWC = [[EntriesWindowController alloc] init];
                                            }
                                            
                                            AppDelegate *appDelegate = [NSApp delegate];
                                            [appDelegate.window close];
                                            
                                            [_entriesWC showWindow:sender];
                                            [_entriesWC.tableView reloadData];
                                        }
                                        
                                    }];
                                    
                                }];
                                
                            }
                        }
                        
                    }];
                    
                }];
            }
        }];
        
    }];
}

@end
