//
//  CommentsWindowController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/13/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "CommentsWindowController.h"
#import "CommentCell.h"
#import "APIStore.h"
#import "CommentEditorWindowController.h"
#import "BlogEntryCell.h"

NSString *CellIdentifier = @"CommentCell";

@interface CommentsWindowController ()

@end

@implementation CommentsWindowController

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
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // KVC
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:NumberOfCommentsCacheKeyPath
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:NumberOfEntriesKeyPath
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(commentChanged:)
                                                 name:CommentChangedNotification
                                               object:nil];
    
    // set table view clicking action
    [self.tableView setDoubleAction:@selector(doubleClick:)];
    [self.tableView setTarget:self];
}

-(void)dealloc
{
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfCommentsCacheKeyPath];
    
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark - Loading

-(void)loadCommentKeys
{
    // get blogEntry key
    NSString *entryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry][0];
    
    // get number of comments
    NSNumber *numberOfComments = [[APIStore sharedStore].numberOfCommentsCache objectForKey:entryKey];
    
    NSUInteger count = numberOfComments.integerValue;
    
    // add keys to array
    NSMutableArray *commentKeys = [[NSMutableArray alloc] init];
    
    void (^ addToArray) (NSInteger);
    
    addToArray = ^(NSInteger commentIndex) {
        
        NSString *key = [NSString stringWithFormat:@"%ld", commentIndex];
        [commentKeys addObject:key];
    };
    
    if (!self.ascendingOrder) {
        
        for (NSInteger i = count - 1; i >= 0; i--) {
            addToArray(i);
        }
    }
    
    else {
        
        for (NSInteger i = 0; i < count; i++) {
            addToArray(i);
        }
    }
    
    _commentKeys = commentKeys;
}

-(void)loadCommentsForBlogEntry:(NSManagedObject *)blogEntry
{
    [self showWindow:nil];
    
    _blogEntry = blogEntry;
    
    [self loadCommentKeys];
    
    [self.tableView reloadData];
}

#pragma mark - Get Model object

-(NSUInteger)commentIndexForRow:(NSUInteger)row
{
    // get comment index key
    NSString *commentIndexKey = [_commentKeys objectAtIndex:row];
    NSUInteger commentIndex = commentIndexKey.integerValue;
    
    return commentIndex;
}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _commentKeys.count;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    
    // make table cell view
    CommentCell *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                    owner:self];
    
    // get model object
    NSUInteger commentIndex = [self commentIndexForRow:row];
    NSManagedObject *comment = [[APIStore sharedStore] cachedComment:commentIndex
                                                        forBlogEntry:self.blogEntry];
    
    void (^setComment) (NSManagedObject *);
    
    setComment = ^(NSManagedObject *comment) {
        
        cell.textField.stringValue = [comment valueForKey:@"content"];
        
        NSDate *date = [comment valueForKey:@"date"];
        
        cell.dateTextField.stringValue = [_dateFormatter stringFromDate:date];
        
        NSManagedObject *user = [comment valueForKey:@"user"];
        
        cell.usernameTextField.stringValue = [user valueForKey:@"username"];
        
    };
    
    if (comment) {
        
        setComment(comment);
    }
    else {
        
        // get the blog entry index
        NSString *entryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry][0];
        
        [[APIStore sharedStore] fetchComment:commentIndex forEntry:entryKey.integerValue withCompletion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    
                    [NSApp presentError:error
                         modalForWindow:self.window
                               delegate:nil
                     didPresentSelector:nil
                            contextInfo:nil];
                }
                else {
                    
                    // get comment from cache
                    NSManagedObject *comment = [[APIStore sharedStore] cachedComment:commentIndex
                                                                        forBlogEntry:self.blogEntry];
                    
                    setComment(comment);
                }
                
            }];
        }];
    }
    
    return cell;
}

#pragma mark - Commands

-(void)newDocument:(id)sender
{
    if (!_editorWC) {
        _editorWC = [[CommentEditorWindowController alloc] init];
        
        [_editorWC showWindow:nil];
    }
    
    [_editorWC loadNewCommentForBlogEntry:self.blogEntry];
    
    [_editorWC showWindow:nil];
}

-(void)doubleClick:(id)sender
{
    if (!_editorWC) {
        _editorWC = [[CommentEditorWindowController alloc] init];
        
        [_editorWC showWindow:nil];
    }
    
    // get comment
    NSUInteger commentIndex = [self commentIndexForRow:self.tableView.selectedRow];
    
    NSManagedObject *comment = [[APIStore sharedStore] cachedComment:commentIndex
                                                        forBlogEntry:self.blogEntry];
    
    [_editorWC loadComment:comment];
    
    [_editorWC showWindow:nil];
}

-(void)delete:(id)sender
{
    // get indexes
    NSUInteger commentIndex = [self commentIndexForRow:self.tableView.selectedRow];
    
    NSString *blogEntryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry][0];
    
    [[APIStore sharedStore] removeComment:commentIndex forEntry:blogEntryKey.integerValue completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           
            if (error) {
                
                [NSApp presentError:error
                     modalForWindow:self.window
                           delegate:nil
                 didPresentSelector:nil
                        contextInfo:nil];
                
            }
            
            else {
                
                // successfully removed comment
                
            }
            
        }];
        
    }];
    
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
    // reload tableView if number of comments changes
    if ([keyPath isEqualToString:NumberOfCommentsCacheKeyPath] && object == [APIStore sharedStore]) {
        
        [self loadCommentKeys];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self.tableView reloadData];
            
        }];
    }
    
    // check if blogEntry was deleted
    if ([keyPath isEqualToString:NumberOfEntriesKeyPath] && object == [APIStore sharedStore]) {
        
        NSArray *keys = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry];
        
        if (!keys.count) {
            
            [self close];
        }
        
    }
}

#pragma mark - Notifications

-(void)commentChanged:(NSNotification *)notification
{
    // check to see if the comment changed belongs to our blog entry
    NSManagedObject *comment = notification.object;
    
    if ([comment valueForKey:@"blogEntry"] == self.blogEntry) {
        
        NSNumber *commentIndex = [comment valueForKey:@"index"];
        
        // get the cell
        NSUInteger row = [_commentKeys indexOfObject:[NSString stringWithFormat:@"%@", commentIndex]];
        CommentCell *cell = [self.tableView viewAtColumn:0
                                                       row:row
                                           makeIfNecessary:NO];
        
        if (cell) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                // update content
                cell.textField.stringValue = [comment valueForKey:@"content"];
                
            }];
        }
        
    }
}

@end
