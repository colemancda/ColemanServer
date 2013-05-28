//
//  PageViewController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "PageViewController.h"
#import "AppDelegate.h"

@interface PageViewController ()

@end

@implementation PageViewController

-(void)pushViewController:(PageViewController *)viewController
{
    AppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.pageController navigateForwardToObject:viewController];
    
    [viewController viewDidLoad];
}

-(void)popViewController
{
    AppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.pageController navigateBack:nil];
    
}

-(void)popToRootViewController
{
    AppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.pageController takeSelectedIndexFrom:[NSNumber numberWithInteger:0]];
    
}

@end
