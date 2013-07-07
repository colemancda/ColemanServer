//
//  EntriesWindowController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "EntriesWindowController.h"
#import "AppDelegate.h"
#import "MainMenuController.h"
#import "BlogEntryCell.h"
#import "EntryEditorWindowController.h"

static NSString *CellIdentifier = @"CellIdentifier";

static NSString *NumberOfEntriesKVC = @"self.numberOfEntries";

@interface EntriesWindowController ()

@end

@implementation EntriesWindowController

-(id)init
{
    self = [self initWithWindowNibName:NSStringFromClass(self.class)
                                 owner:self];
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // KVC
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:NumberOfEntriesKVC
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
}

-(void)dealloc
{
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKVC];
    
}

#pragma mark - KVC
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:NumberOfEntriesKVC] && object == [APIStore sharedStore]) {
        
        [self.tableView reloadData];
    }

}

#pragma mark - NSTableView

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [APIStore sharedStore].numberOfEntries.integerValue;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                    owner:self];
    
    // get blog entry
    NSString *indexKey = [NSString stringWithFormat:@"%ld", row];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    cell.textField.stringValue = [blogEntry valueForKey:@"title"];
    
    return cell;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView.selectedRow != -1) {
        
        // get the cell
        BlogEntryCell *cell = [self.tableView viewAtColumn:0
                                                       row:self.tableView.selectedRow
                                           makeIfNecessary:NO];
        
        // make first responder
        [self.window makeFirstResponder:cell];
        
    }
    
}

#pragma mark - Commands

-(IBAction)signOut:(id)sender
{
    // show login window
    AppDelegate *appDelegate = [NSApp delegate];
    [appDelegate.window makeKeyAndOrderFront:nil];
    
    // close this window
    [self.window close];
}

-(void)createNewEntry:(id)sender
{
    _editorWC = [[EntryEditorWindowController alloc] initWithNewEntry];
    
    [self.window addChildWindow:_editorWC.window
                        ordered:NSWindowAbove];
    
    [_editorWC showWindow:sender];
    
}



@end
