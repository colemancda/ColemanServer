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
        
        // date formatter
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // KVC
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:NumberOfEntriesKeyPath
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
    // changes notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blogEntryChanged:)
                                                 name:BlogEntryEditedNotification
                                               object:nil];
    
    // set double click action
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.target = self;
    
}

-(void)dealloc
{
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - KVC
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    if ([keyPath isEqualToString:NumberOfEntriesKeyPath] && object == [APIStore sharedStore]) {
        
        [self.tableView reloadData];
    }

}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [APIStore sharedStore].numberOfEntries.integerValue;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    BlogEntryCell *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                    owner:self];
    
    // get blog entry
    NSString *indexKey = [NSString stringWithFormat:@"%ld", row];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    if (!blogEntry) {
        
        [NSException raise:@"Error in NSTableView DataSource Protocol"
                    format:@"There is no object for the row requested"];
        return nil;
    }
    
    // set basic info
    cell.textField.stringValue = [blogEntry valueForKey:@"title"];
    cell.contentTextField.stringValue = [blogEntry valueForKey:@"content"];
    
    NSDate *date = [blogEntry valueForKey:@"date"];
    cell.dateTextField.stringValue = [self.dateFormatter stringFromDate:date];
    
    
    return cell;
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

-(IBAction)delete:(id)sender
{
    [[APIStore sharedStore] removeEntry:self.tableView.selectedRow completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error
                     modalForWindow:self.window
                           delegate:nil
                 didPresentSelector:nil
                        contextInfo:nil];
            }
            else {
                
                
                
            }
            
        }];
    }];
    
}

-(IBAction)doubleClick:(id)sender
{
    // edit entry
    if (self.tableView.selectedRow != -1) {
        
        _editorWC = [[EntryEditorWindowController alloc] initWithEntry:self.tableView.selectedRow];
        
        [self.window addChildWindow:_editorWC.window
                            ordered:NSWindowAbove];
        
        [_editorWC showWindow:sender];
        
    }
}

#pragma mark - Conditionally enable menu items

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(delete:)) {
        
        // check if any row is selected
        if (self.tableView.selectedRow == -1) {
            
            return NO;
            
        }
        else {
            return YES;
        }
        
    }
    
    return YES;
}

#pragma mark - Blog Entry Changed Notification

-(void)blogEntryChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}


@end
