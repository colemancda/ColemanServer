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
}

@property (readonly) BlogEntryEditorMode mode;

@property (readonly) NSInteger blogEntryIndex;

@property (strong) IBOutlet NSImageView *imageView;

@property (strong) IBOutlet NSTextField *titleTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

@property (strong) IBOutlet NSTextField *dateTextField;

- (IBAction)saveDocument:(id)sender;

#pragma mark - Actions

-(void)uploadImage:(NSImage *)image;

#pragma mark - Initialization

- (id)initWithEntry:(NSUInteger)index;

- (id)initWithNewEntry;


@end
