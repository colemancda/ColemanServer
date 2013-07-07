//
//  EntryEditorWindowController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/7/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "EntryEditorWindowController.h"
#import "APIStore.h"

@interface EntryEditorWindowController ()

@end

@implementation EntryEditorWindowController

- (id)initWithEntry:(NSUInteger)index
{
    self = [self initWithWindowNibName:NSStringFromClass([self class])
                                 owner:self];
    if (self) {
        
        _blogEntryIndex = index;
        _mode = ExistingEntry;
        
    }
    return self;
}

-(id)initWithNewEntry
{
    self = [self initWithWindowNibName:NSStringFromClass([self class])
                                 owner:self];
    if (self) {
        
        _mode = NewEntry;
        
    }
    return self;
}

-(id)init
{
    return self.initWithNewEntry;
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
    
    // start observing numberOfEntries
    [[APIStore sharedStore] addObserver:self
                             forKeyPath:NumberOfEntriesKeyPath
                                options:NSKeyValueObservingOptionOld
                                context:nil];
    
    // date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    if (_mode == ExistingEntry) {
        
        // get the entry from the store
        NSString *indexKey = [NSString stringWithFormat:@"%ld", (long)self.blogEntryIndex];
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
        
        // set the UI
        self.titleTextField.stringValue = [blogEntry valueForKey:@"title"];
        self.contentTextView.string = [blogEntry valueForKey:@"content"];
        
        NSString *dateString = [dateFormatter stringFromDate:[blogEntry valueForKey:@"date"]];
        self.dateTextField.stringValue = dateString;
    }
    
    else {
        
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        self.dateTextField.stringValue = dateString;
        
    }
}

-(void)dealloc
{
    // close window
    [self.window close];
    
    // KVC
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
    
}

#pragma mark - KVC

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    if ([keyPath isEqualToString:NumberOfEntriesKeyPath] && object == [APIStore sharedStore]) {
        
        // check if any entry was removed...
        
        // get the old value
        NSNumber *oldNumberOfEntries = [change objectForKey:NSKeyValueChangeOldKey];
        
        // if a entry was removed
        if (oldNumberOfEntries.integerValue > [APIStore sharedStore].numberOfEntries.integerValue) {
            
            // check if our entry was removed
            NSString *indexKey = [NSString stringWithFormat:@"%ld", self.blogEntryIndex];
            NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
            
            if (!blogEntry) {
                
                [self.window close];
            }
        }
    }
    
}

#pragma mark - Save Action

-(void)saveDocument:(id)sender
{
    NSString *title = self.titleTextField.stringValue;
    NSString *content = self.contentTextView.string;
    NSImage *image = self.imageView.image;
    
    // if new entry
    if (self.mode == NewEntry) {
        
        [[APIStore sharedStore] createEntryWithTitle:title content:content withCompletion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (error) {
                    
                    [NSApp presentError:error
                         modalForWindow:self.window
                               delegate:nil
                     didPresentSelector:nil
                            contextInfo:nil];
                }
                else {
                    
                    // change editor mode to edit
                    _mode = ExistingEntry;
                    _blogEntryIndex = [APIStore sharedStore].numberOfEntries.integerValue - 1;
                    
                }
            }];
        }];
    }
    
    else {
        
        // get the blogEntry
        NSString *indexKey = [NSString stringWithFormat:@"%lu", self.blogEntryIndex];
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
        
        // check what changed...
        NSMutableDictionary *changes = [[NSMutableDictionary alloc] init];
        
        if (![[blogEntry valueForKey:@"title"] isEqualToString:title]) {
            
            [changes setObject:title
                        forKey:@"title"];
            
        }
        
        if (![[blogEntry valueForKey:@"content"] isEqualToString:content]) {
            
            [changes setObject:content
                        forKey:@"content"];
            
        }
        
        // if no changes occurred
        if (changes.allKeys.count == 0) {
            
            return;
        }
        
        [[APIStore sharedStore] editEntry:self.blogEntryIndex changes:changes completion:^(NSError *error) {
            
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
}

@end