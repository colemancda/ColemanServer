//
//  AppDelegate.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/2/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"

extern NSString *const kErrorDomain;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSBox *box;

@property NSViewController *rootViewController;

@end
