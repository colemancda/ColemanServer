//
//  CommentsWindowController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/13/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CommentEditorWindowController;

@interface CommentsWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSArray *_commentKeys;
    
    NSDateFormatter *_dateFormatter;
}

@property (readonly) NSManagedObject *blogEntry;

@property (readonly) BOOL ascendingOrder;

@property (strong) IBOutlet NSTableView *tableView;

@property (readonly) CommentEditorWindowController *editorWC;

#pragma mark

-(void)loadCommentKeys;

-(void)loadCommentsForBlogEntry:(NSManagedObject *)blogEntry;

#pragma mark - Model Object

-(NSUInteger)commentIndexForRow:(NSUInteger)row;

#pragma mark - Commands

-(IBAction)newDocument:(id)sender;

-(IBAction)doubleClick:(id)sender;

#pragma mark - Notifications

-(void)commentChanged:(NSNotification *)notification;

@end
