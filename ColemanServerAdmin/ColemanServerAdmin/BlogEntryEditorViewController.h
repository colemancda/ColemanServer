//
//  BlogEntryEditorViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PageViewController.h"

@interface BlogEntryEditorViewController : PageViewController

@property (readonly) NSUInteger blogEntryIndex;

@property (strong) IBOutlet NSImageView *imageView;

@property (strong) IBOutlet NSTextField *titleTextField;

@property (strong) IBOutlet NSTextView *contentTextView;

- (IBAction)save:(id)sender;

- (id)initWithEntry:(NSUInteger)index;

@end
