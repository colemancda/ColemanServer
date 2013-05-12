//
//  ToolBarController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "ToolBarController.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "UsersViewController.h"
#import "SaveViewController.h"

@implementation ToolBarController

- (IBAction)server:(id)sender {
    
    // load the main VC
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    
    MainViewController *mainVC = [[MainViewController alloc] init];
    
    appDelegate.rootViewController = mainVC;
    
}

- (IBAction)save:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    
    SaveViewController *saveVC = [[SaveViewController alloc] init];
    
    appDelegate.rootViewController = saveVC;
    
}

- (IBAction)users:(id)sender {
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    
    UsersViewController *usersVC = [[UsersViewController alloc] init];
    
    appDelegate.rootViewController = usersVC;
}

@end
