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
@class BlogEntryCell;

@interface EntriesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
    NSMutableArray *_blogEntries;
}

@property (strong) IBOutlet NSTableView *tableView;

@property (strong) IBOutlet NSScrollView *tableViewScrollView;

@property (readonly) EntryEditorWindowController *editorWC;

@property NSDateFormatter *dateFormatter;

-(IBAction)createNewEntry:(id)sender;

#pragma mark

-(void)addCacheToTableView;

#pragma mark - Blog Entry Changed Notification

-(void)blogEntryChanged:(NSNotification *)notification;

-(void)blogEntryDownloaded:(NSNotification *)notification;

-(void)blogEntryImageDownloaded:(NSNotification *)notification;

@end
