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
        
        _blogEntries = [[NSMutableArray alloc] init];
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
    // download notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blogEntryDownloaded:)
                                                 name:BlogEntryFetchedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blogEntryImageDownloaded:)
                                                 name:BlogEntryImageFetchedNotification
                                               object:nil];
    
    // set double click action
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.target = self;
    
    // download all the entries data but lazily load image data...
    [self.tableView setHidden:YES];
    
    // fetch numberOfEntries
    [[APIStore sharedStore] fetchNumberOfEntriesWithCompletion:^(NSError *error) {
       
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

-(void)dealloc
{
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.window close];
    
    _editorWC = nil;
    
}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _blogEntries.count;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    BlogEntryCell *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                    owner:self];
    // get blogEntry
    NSManagedObject *blogEntry = _blogEntries[row];
    
    // set basic info
    cell.textField.stringValue = [blogEntry valueForKey:@"title"];
    cell.contentTextField.stringValue = [blogEntry valueForKey:@"content"];
    
    NSDate *date = [blogEntry valueForKey:@"date"];
    cell.dateTextField.stringValue = [self.dateFormatter stringFromDate:date];
    
    // set image
    NSData *imageData = [blogEntry valueForKey:@"image"];
    if (imageData) {
        
        cell.imageView.image = [[NSImage alloc] initWithData:imageData];
    }
    else {
        
        cell.imageView.image = nil;
    }
    
    return cell;
}

#pragma mark - Commands

-(void)createNewEntry:(id)sender
{
    _editorWC = [[EntryEditorWindowController alloc] initWithNewEntry];
    
    [_editorWC showWindow:sender];
}

-(IBAction)delete:(id)sender
{
    NSManagedObject *blogEntry = _blogEntries[self.tableView.selectedRow];
    
    // get key
    NSString *key = [[APIStore sharedStore].blogEntriesCache allKeysForObject:blogEntry][0];
    
    NSInteger index = key.integerValue;
    
    [[APIStore sharedStore] removeEntry:index completion:^(NSError *error) {
        
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
        
        NSManagedObject *blogEntry = _blogEntries[self.tableView.selectedRow];
        
        // get key
        NSString *key = [[APIStore sharedStore].blogEntriesCache allKeysForObject:blogEntry][0];
        
        NSInteger index = key.integerValue;
        
        _editorWC = [[EntryEditorWindowController alloc] initWithEntry:index];
        
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

#pragma mark - KVC
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    if ([keyPath isEqualToString:NumberOfEntriesKeyPath] && object == [APIStore sharedStore]) {
                
        [self addCacheToTableView];
        
    }
    
}

#pragma mark - Blog Entry Notifications

-(void)blogEntryChanged:(NSNotification *)notification
{
    
    
    
}

-(void)blogEntryDownloaded:(NSNotification *)notification
{
    
    [self addCacheToTableView];
    
    // check if its the last one downloaded
    NSManagedObject *blogEntry = notification.object;
    
    NSString *key = [[APIStore sharedStore].blogEntriesCache allKeysForObject:blogEntry][0];
    NSInteger index = key.integerValue;
    
    // if last object that need to be downloaded
    if (index == 0) {
        
        // show table view
        [self.tableView setHidden:NO];
        
        [self.tableView reloadData];
        
    }
}

-(void)blogEntryImageDownloaded:(NSNotification *)notification
{
    
    
    
}

#pragma mark

-(void)addCacheToTableView
{
    NSUInteger count = [APIStore sharedStore].numberOfEntries.integerValue;
    
    // add each blogEntry to our array in reverse order
    for (NSInteger i = count - 1; i >= 0; i--) {
        
        // get blogEntry
        NSString *indexKey = [NSString stringWithFormat:@"%ld", i];
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache valueForKey:indexKey];
        
        if (blogEntry) {
            
            [_blogEntries addObject:blogEntry];
        }
        
        // if not in cache, we download it
        else {
            
            _blogEntries = [[NSMutableArray alloc] init];
            
            [[APIStore sharedStore] fetchEntry:i completion:^(NSError *error) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    if (error) {
                        
                        [NSApp presentError:error];
                        
                    }
                    else {
                        
                        
                        
                    }
                    
                }];
                
            }];
            
            // end method
            return;
        }
    }
}

@end
