//
//  EntriesWindowController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "APIStore.h"
#import "EntryEditorWindowController.h"

@interface EntriesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) IBOutlet NSTableView *tableView;

@property (readonly) EntryEditorWindowController *editorWC;

@property NSDateFormatter *dateFormatter;

-(IBAction)createNewEntry:(id)sender;

#pragma mark - Get model object

-(NSInteger)blogEntryIndexForRow:(NSInteger)row;

#pragma mark - Blog Entry Changed Notification

-(void)blogEntryChanged:(NSNotification *)notification;

@end
