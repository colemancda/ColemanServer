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
#import "CommentsWindowController.h"

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
    
    // download number of entries data but lazily load info & image data...
    self.window.alphaValue = 0.0;
    
    // fetch numberOfEntries
    [[APIStore sharedStore] fetchNumberOfEntriesWithCompletion:^(NSError *error) {
       
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            if (error) {
                
                [NSApp presentError:error];
                
            }
            else {
                
                [self showWindowAnimated];
                
            }
        }];
    }];
    
}

-(void)dealloc
{    
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _blogEntryKeys.count;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    BlogEntryCell *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                    owner:self];
    
    // get key
    NSString *entryKey = _blogEntryKeys[row];
    
    // get blogEntry
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:entryKey];
    
    if (blogEntry) {
        
        [cell setBlogEntry:blogEntry];
        
    }
    else {
        
        [[APIStore sharedStore] fetchEntry:entryKey.integerValue completion:^(NSError *error) {
           
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    [NSApp presentError:error];
                }
                else {
                    
                    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:entryKey];
                    
                    [cell setBlogEntry:blogEntry];
                }
            }];
        }];
    }
    
    // image...
    
    // set image
    NSData *imageData = [blogEntry valueForKey:@"image"];
    if (imageData) {
        
        cell.imageView.image = [[NSImage alloc] initWithData:imageData];
    }
    else {
        
        cell.imageView.image = nil;
        
        // lazy load image...
        [[APIStore sharedStore] fetchImageForEntry:entryKey.integerValue completion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    
                    [NSApp presentError:error];
                    
                }
                else {
                    
                    NSData *imageData = [blogEntry valueForKey:@"image"];
                    
                    if (imageData) {
                        cell.imageView.image = [[NSImage alloc] initWithData:imageData];
                    }
                }
                
            }];
            
        }];
    }
    
    // number of comments...
    
    // get number of comments
    NSNumber *numberOfComments = [[APIStore sharedStore].numberOfCommentsCache objectForKey:entryKey];
    
    if (numberOfComments) {
        
        [cell setNumberOfComments:numberOfComments];
    }
    // lazy load number of comments
    else {
        
        [[APIStore sharedStore] fetchNumberOfCommentsForEntry:entryKey.integerValue withCompletion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    
                    [NSApp presentError:error];
                }
                else {
                    
                    // get number of comments
                    NSNumber *numberOfComments = [[APIStore sharedStore].numberOfCommentsCache objectForKey:entryKey];
                    
                    [cell setNumberOfComments:numberOfComments];
                }
                
            }];
            
        }];
    }
    
    return cell;
}

#pragma mark - Commands

-(void)showComments:(id)sender
{
    if (self.tableView.selectedRow != -1) {
        
        NSString *entryKey = _blogEntryKeys[self.tableView.selectedRow];
        
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:entryKey];
        
        if (!_commentsWC) {
            _commentsWC = [[CommentsWindowController alloc] init];
            
            [_commentsWC showWindow:nil];
        }
        
        [_commentsWC loadCommentsForBlogEntry:blogEntry];
    }
}

-(void)newDocument:(id)sender
{
    if (!_editorWC) {
        _editorWC = [[EntryEditorWindowController alloc] init];
        
        [_editorWC showWindow:nil];
    }
    
    [_editorWC loadNewBlogEntry];
    
    
}

-(IBAction)doubleClick:(id)sender
{
    // edit entry
    if (self.tableView.selectedRow != -1) {
        
        NSString *entryKey = _blogEntryKeys[self.tableView.selectedRow];
        
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:entryKey];
        
        if (!_editorWC) {
            _editorWC = [[EntryEditorWindowController alloc] init];
            
            [_editorWC showWindow:nil];
        }
        
        [_editorWC loadBlogEntry:blogEntry];
        
    }
}

-(IBAction)delete:(id)sender
{
    NSString *entryKey = _blogEntryKeys[self.tableView.selectedRow];
    
    [[APIStore sharedStore] removeEntry:entryKey.integerValue completion:^(NSError *error) {
        
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

#pragma mark - Conditionally enable menu items

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(delete:) ||
        menuItem.action == @selector(showComments:)) {
        
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
                
        [self loadEntryKeys];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            [self.tableView reloadData];
            
        }];
    }
}

#pragma mark - Blog Entry Notifications

-(void)blogEntryChanged:(NSNotification *)notification
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        // get blogEntry
        NSManagedObject *blogEntry = notification.object;
        
        // entry key
        NSString *entryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:blogEntry][0];
        
        // get row
        NSUInteger row = [_blogEntryKeys indexOfObject:entryKey];
        
        BlogEntryCell *cell = [self.tableView viewAtColumn:0
                                                       row:row
                                           makeIfNecessary:NO];
        
        if (cell) {
            
            [cell setBlogEntry:blogEntry];
        }
    }];
}

#pragma mark

-(void)loadEntryKeys
{
    // get the numberOfEntries
    NSUInteger count = [APIStore sharedStore].numberOfEntries.integerValue;
    
    // add each key to array
    NSMutableArray *blogEntryKeys = [[NSMutableArray alloc] init];
    
    for (NSInteger i = count - 1; i >= 0; i--) {
        
        NSString *indexKey = [NSString stringWithFormat:@"%ld", i];
        
        [blogEntryKeys addObject:indexKey];
        
    }
    
    _blogEntryKeys = blogEntryKeys;
}

-(void)showWindowAnimated
{    
    // show table view
    [self.tableView reloadData];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.9];
    
    [self.window.animator setAlphaValue:1.0];
    
    [NSAnimationContext endGrouping];
    
    // animate window frame
    NSRect originalFrame = self.window.frame;
    
    NSRect newFrame;
    newFrame.origin.x = originalFrame.origin.x;
    newFrame.origin.y = -originalFrame.size.height;
    newFrame.size = originalFrame.size;
    
    // set offscreen without animation
    [self.window setFrame:newFrame
                  display:YES
                  animate:NO];
    
    // animate
    [self.window setFrame:originalFrame
                  display:YES
                  animate:YES];
    
}

@end
