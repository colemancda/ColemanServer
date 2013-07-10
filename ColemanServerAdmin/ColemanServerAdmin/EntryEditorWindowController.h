//
//  EntryEditorWindowController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/7/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, BlogEntryEditorMode) {
    
    NewEntry,
    ExistingEntry
};

@interface EntryEditorWindowController : NSWindowController
{
    NSImage *_initialImage;
    
    NSDateFormatter *_dateFormatter;
}

@property (readonly) BlogEntryEditorMode mode;

@property (readonly) NSManagedObject *blogEntry;

@property (strong) IBOutlet NSImageView *imageView;

@property (strong) IBOutlet NSTextField *titleTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

@property (strong) IBOutlet NSTextField *dateTextField;

- (IBAction)saveDocument:(id)sender;

#pragma mark - Actions

-(void)uploadImage:(NSImage *)image;

#pragma mark - Load WC

-(void)loadBlogEntry:(NSManagedObject *)blogEntry;

-(void)loadNewBlogEntry;

@end
