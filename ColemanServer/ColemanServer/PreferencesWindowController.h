//
//  PreferencesWindowController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/5/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DataStore;

@interface PreferencesWindowController : NSWindowController

@property (readonly) DataStore *dataStore;

@end
