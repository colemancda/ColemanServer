//
//  MainMenuController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EntriesWindowController;

@interface MainMenuController : NSObject <NSWindowDelegate>

@property (weak) IBOutlet NSTextField *usernameTextField;

@property (weak) IBOutlet NSSecureTextField *passwordTextField;

@property (weak) IBOutlet NSTextField *urlTextField;

- (IBAction)connect:(id)sender;

#pragma mark

@property (readonly) EntriesWindowController *entriesWC;


@end
