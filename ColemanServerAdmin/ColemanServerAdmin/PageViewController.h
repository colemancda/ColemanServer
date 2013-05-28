//
//  PageViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PageViewController : NSViewController

-(void)viewDidLoad;

-(void)viewDidAppear;

#pragma mark - Navigation

-(void)pushViewController:(PageViewController *)viewController;

-(void)popViewController;

-(void)popToRootViewController;

@end
