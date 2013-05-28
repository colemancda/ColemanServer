//
//  AppDelegate.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PageViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSPageControllerDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (strong) IBOutlet NSPageController *pageController;

@property (strong) IBOutlet NSBox *box;

@property (readonly) PageViewController *rootVC;

#pragma mark

+(NSString *)bundleID;

+(NSString *)errorDomain;



@end
