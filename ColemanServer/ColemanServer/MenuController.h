//
//  MenuController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/4/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class  PreferencesWindowController;

@interface MenuController : NSObject
{
    PreferencesWindowController *_preferencesWC;
}

-(IBAction)preferences:(id)sender;

-(IBAction)save:(id)sender;

-(IBAction)openLogs:(id)sender;

-(IBAction)print:(id)sender;

@end
