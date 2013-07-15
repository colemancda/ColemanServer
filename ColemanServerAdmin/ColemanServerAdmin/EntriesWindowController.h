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
@class BlogEntryCell, EntriesWindowController, CommentsWindowController;

@interface EntriesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
{
    NSArray *_blogEntryKeys;
}

@property (strong) IBOutlet NSTableView *tableView;

@property (strong) IBOutlet NSScrollView *tableViewScrollView;

@property (readonly) EntryEditorWindowController *editorWC;

@property (readonly) CommentsWindowController *commentsWC;

@property NSDateFormatter *dateFormatter;

-(IBAction)newDocument:(id)sender;

-(IBAction)showComments:(id)sender;

#pragma mark

-(void)addCacheToTableView;

-(void)loadEntryKeys;

-(void)showWindowAnimated;

#pragma mark - Blog Entry Changed Notification

-(void)blogEntryChanged:(NSNotification *)notification;

-(void)blogEntryDownloaded:(NSNotification *)notification;

-(void)blogEntryImageDownloaded:(NSNotification *)notification;

@end
