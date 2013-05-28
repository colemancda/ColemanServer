//
//  SaveViewController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SaveViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSTableView *tableView;

@property (readonly) NSArray *saveOptions;

#pragma mark

-(IBAction)saveLog:(id)sender;

-(IBAction)blogSave:(id)sender;

-(IBAction)blogBackup:(id)sender;

-(IBAction)usersSave:(id)sender;

-(IBAction)usersBackup:(id)sender;

@end
