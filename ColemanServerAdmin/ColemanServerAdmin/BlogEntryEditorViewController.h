//
//  BlogEntryEditorViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlogEntryEditorViewController : NSViewController

@property (readonly) NSUInteger blogEntryIndex;

@property (strong) IBOutlet NSImageView *imageView;

@property (strong) IBOutlet NSTextField *titleTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

@property (strong) IBOutlet NSTextField *dateTextField;

- (IBAction)save:(id)sender;

- (id)initWithEntry:(NSUInteger)index;

@end
