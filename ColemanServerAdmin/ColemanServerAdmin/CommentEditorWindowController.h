//
//  CommentEditorWindowController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/14/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CommentEditorMode) {
    
    NewCommment,
    ExistingCommment
    
};

@interface CommentEditorWindowController : NSWindowController
{
    NSDateFormatter *_dateFormatter;
    
}

@property (strong) IBOutlet NSTextField *usernameTextField;

@property (strong) IBOutlet NSTextField *dateTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

@property (readonly) CommentEditorMode mode;

@property (readonly) NSManagedObject *comment;

@property (readonly) NSManagedObject *blogEntry;

#pragma mark - Loading

-(void)loadNewCommentForBlogEntry:(NSManagedObject *)blogEntry;

-(void)loadComment:(NSManagedObject *)comment;

#pragma mark

-(IBAction)saveDocument:(id)sender;



@end
