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

- (IBAction)save:(id)sender {
    
    NSString *title = self.titleTextField.stringValue;
    NSString *content = self.contentTextView.string;
    
    // if new entry
    if (self.mode == NewEntry) {
        
        [[APIStore sharedStore] createEntryWithTitle:title content:content withCompletion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (error) {
                    
                    [NSApp presentError:error];
                    
                    return;
                }
                
                // show success
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Successfully created new blog entry", @"Successfully created new blog entry")
                                                 defaultButton:NSLocalizedString(@"OK", @"OK")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@""];
                
                [alert beginSheetModalForWindow:self.window
                                  modalDelegate:nil
                                 didEndSelector:nil
                                    contextInfo:nil];
                
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
                    
                    [NSApp presentError:error];
                    
                    return;
                }
                
                else {
                    
                    // show sucess modal
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Successfully saved blog entry", @"Successfully saved blog entry")
                                                     defaultButton:NSLocalizedString(@"OK", @"OK")
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@""];
                    
                    [alert beginSheetModalForWindow:self.window
                                      modalDelegate:nil
                                     didEndSelector:nil
                                        contextInfo:nil];
                }
                
            }];
            
        }];
        
    }
}

-(void)cancel:(id)sender
{
    [self.window close];
}

@end
