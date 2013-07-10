//
//  EntryEditorWindowController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/7/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "EntryEditorWindowController.h"
#import "APIStore.h"
#import "AppDelegate.h"

@interface EntryEditorWindowController ()

@end

@implementation EntryEditorWindowController

-(id)init
{
    self = [self initWithWindowNibName:NSStringFromClass([self class])
                                 owner:self];
    if (self) {
        
        
        
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        
        // start observing numberOfEntries
        [[APIStore sharedStore] addObserver:self
                                 forKeyPath:NumberOfEntriesKeyPath
                                    options:NSKeyValueObservingOptionOld
                                    context:nil];
        
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

-(void)dealloc
{
    // close window
    [self.window close];
    
    // KVC
    [[APIStore sharedStore] removeObserver:self
                                forKeyPath:NumberOfEntriesKeyPath];
}

#pragma mark - Load WC

-(void)loadBlogEntry:(NSUInteger)entryIndex
{
    
    [self showWindow:nil];
    self.window.alphaValue = 0;
    
    _blogEntryIndex = entryIndex;
    _mode = ExistingEntry;
    
    // get the entry from the store
    NSString *indexKey = [NSString stringWithFormat:@"%ld", (long)self.blogEntryIndex];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    // set the UI
    self.titleTextField.stringValue = [blogEntry valueForKey:@"title"];
    NSString *content = [blogEntry valueForKey:@"content"];
    
    // a copy becuase NSTextView tracks changes
    self.contentTextView.string = content.copy;
    
    NSString *dateString = [_dateFormatter stringFromDate:[blogEntry valueForKey:@"date"]];
    self.dateTextField.stringValue = dateString;
    
    // get image data
    NSData *imageData = [blogEntry valueForKey:@"image"];
    
    // if the entry has an image
    if (imageData) {
        
        // set existing image
        _initialImage = [[NSImage alloc] initWithData:imageData];
        
        self.imageView.image = _initialImage;
    }
    
    self.window.alphaValue = 1;

}

-(void)loadNewBlogEntry
{
    [self showWindow:nil];
    self.window.alphaValue = 0;
    
    _mode = NewEntry;
    
    NSString *dateString = [_dateFormatter stringFromDate:[NSDate date]];
    self.dateTextField.stringValue = dateString;
    
    self.window.alphaValue = 1;
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
        if ([oldNumberOfEntries isKindOfClass:[NSNull class]]) {
            oldNumberOfEntries = @0;
        }
        
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
    NSImage *image = self.imageView.image;
    
    // we give it a copy of the content string becuase NSTextView will track the changes
    NSString *content = self.contentTextView.string.copy;
    
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
                    
                    if (image) {
                        
                        // try to upload image
                        [self uploadImage:image];
                    }
                }
            }];
        }];
    }
    
    // if exisitng entry is being saved
    else {
        
        // get the blogEntry
        NSString *indexKey = [NSString stringWithFormat:@"%ld", self.blogEntryIndex];
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
        if (changes.allKeys.count != 0) {
            
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
                        
                        // successfully uploaded entry changes
                        
                    }
                    
                }];
                
            }];
            
        }
        
        // if the image was changed
        if (image && image != _initialImage) {
            
            [self uploadImage:image];
        }
        
        // if image was erased
        if (_initialImage && !image) {
            
            // delete image
            [[APIStore sharedStore] removeImageFromEntry:self.blogEntryIndex completion:^(NSError *error) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                   
                    if (error) {
                        
                        [NSApp presentError:error
                             modalForWindow:self.window
                                   delegate:nil
                         didPresentSelector:nil
                                contextInfo:nil];
                        
                    }
                    
                 else {
                     
                     // successfully deleted image
                     _initialImage = nil;
                 }
                    
                }];
                
            }];
            
        }
        
    }
}

-(void)uploadImage:(NSImage *)image
{
    NSAssert(image, @"nil argument");
    
    // get image data
    NSBitmapImageRep *imageRepresentation = image.representations[0];
    
    if (!imageRepresentation) {
        
        NSString *description = NSLocalizedString(@"Cannot upload image",
                                                  @"Cannot upload image");
        
        NSString *reason = NSLocalizedString(@"Image format is not Bitmap",
                                             @"Image format is not Bitmap");
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description,
                                   NSLocalizedFailureReasonErrorKey : reason};
        
        NSError *invalidImageFormatError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                               code:50005
                                                           userInfo:userInfo];
        [NSApp presentError:invalidImageFormatError
             modalForWindow:self.window
                   delegate:nil
         didPresentSelector:nil
                contextInfo:nil];
        
        return;
    }
    
    NSData *imageData = [imageRepresentation representationUsingType:NSPNGFileType
                                                          properties:nil];
    
    // upload new image
    [[APIStore sharedStore] setImageData:imageData forEntry:self.blogEntryIndex completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error
                     modalForWindow:self.window
                           delegate:nil
                 didPresentSelector:nil
                        contextInfo:nil];
            }
            else {
                
                // successfully uploaded imaged data
                _initialImage = image;
                
            }
            
        }];
        
    }];
    
}

@end
