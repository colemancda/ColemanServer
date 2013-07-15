//
//  CommentEditorWindowController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/14/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "CommentEditorWindowController.h"
#import "APIStore.h"

@interface CommentEditorWindowController ()

@end

@implementation CommentEditorWindowController

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
    
}

#pragma mark - Loading

-(void)loadNewCommentForBlogEntry:(NSManagedObject *)blogEntry
{
    _mode = NewCommment;
    
    _comment = nil;
    
    _blogEntry = blogEntry;
    
    self.dateTextField.stringValue = [_dateFormatter stringFromDate:[NSDate date]];
    self.usernameTextField.stringValue = [APIStore sharedStore].username;
    self.contentTextView.string = @"";
}

-(void)loadComment:(NSManagedObject *)comment
{
    _comment = comment;
    
    _blogEntry = [comment valueForKey:@"blogEntry"];
    
    _mode = ExistingCommment;
    
    // get values
    NSDate *date = [comment valueForKey:@"date"];
    NSString *content = [comment valueForKey:@"content"];
    
    NSManagedObject *user = [comment valueForKey:@"user"];
    NSString *username = [user valueForKey:@"username"];
    
    // set strings
    self.dateTextField.stringValue = [_dateFormatter stringFromDate:date];
    self.usernameTextField.stringValue = username;
    self.contentTextView.string = content.copy;
    
}

#pragma mark

-(void)saveDocument:(id)sender
{
    // get content string
    NSString *content = self.contentTextView.string.copy;
    
    // get entry index
    NSString *blogEntryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry][0];
    
    // upload changes
    if (self.mode == ExistingCommment) {
        
        NSNumber *commentIndex = [self.comment valueForKey:@"index"];
        
        // check for changes
        if ([[self.comment valueForKey:@"content"] isEqualToString:content]) {
            return;
        }
        
        [[APIStore sharedStore] editComment:commentIndex.integerValue forEntry:blogEntryKey.integerValue changes:content completion:^(NSError *error) {
           
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    
                    [NSApp presentError:error
                         modalForWindow:self.window
                               delegate:nil
                     didPresentSelector:nil
                            contextInfo:nil];
                }
                else {
                    
                    // successfully uploaded changes
                    
                    
                }
                
            }];
            
        }];
        
    }
    
    // create new entry
    else {
        
        [[APIStore sharedStore] createComment:content forEntry:blogEntryKey.integerValue completion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (error) {
                    [NSApp presentError:error
                         modalForWindow:self.window
                               delegate:nil
                     didPresentSelector:nil
                            contextInfo:nil];
                }
                else {
                    
                    // successfully created new comment
                    _mode = ExistingCommment;
                    
                    // get comment...
                    NSString *entryKey = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry][0];
                    
                    NSNumber *numberOfComments = [[APIStore sharedStore].numberOfCommentsCache objectForKey:entryKey];
                    
                    NSUInteger commentIndex = numberOfComments.integerValue - 1;
                    
                    NSOrderedSet *comments = [self.blogEntry valueForKey:@"comments"];
                    
                    for (NSManagedObject *comment in comments) {
                        
                        NSNumber *index = [comment valueForKey:@"index"];
                        
                        if (index.integerValue == commentIndex) {
                            
                            _comment = comment;
                            
                            return;
                        }
                    }
                }
            }];
            
        }];
    }
    
}


@end
