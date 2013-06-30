//
//  BlogEntryEditorViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, BlogEntryEditorMode) {
    
    NewEntry,
    ExistingEntry
};

@interface BlogEntryEditorViewController : NSViewController

@property (readonly) BlogEntryEditorMode mode;

@property (readonly) NSInteger blogEntryIndex;

@property (strong) IBOutlet NSImageView *imageView;

@property (strong) IBOutlet NSTextField *titleTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

@property (strong) IBOutlet NSTextField *dateTextField;

- (IBAction)save:(id)sender;

- (IBAction)cancel:(id)sender;

#pragma mark - Initialization

- (id)initWithEntry:(NSUInteger)index;

- (id)initWithNewEntry;

@end
