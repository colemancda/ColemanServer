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

-(void)loadBlogEntry:(NSManagedObject *)blogEntry
{
    [self showWindow:nil];
    self.window.alphaValue = 0;
    
    _blogEntry = blogEntry;
    _mode = ExistingEntry;
    
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
        
    }
    else {
        
        _initialImage = nil;
        
    }
    
    self.imageView.image = _initialImage;
    
    self.window.alphaValue = 1;

}

-(void)loadNewBlogEntry
{
    [self showWindow:nil];
    self.window.alphaValue = 0;
    
    _mode = NewEntry;
    _blogEntry = nil;
    
    NSString *dateString = [_dateFormatter stringFromDate:[NSDate date]];
    self.dateTextField.stringValue = dateString;
    
    self.titleTextField.stringValue = @"";
    self.contentTextView.string = @"";
    
    _initialImage = nil;
    self.imageView.image = nil;
    
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
        
        if (self.blogEntry) {
            
            NSArray *keys = [[APIStore sharedStore].blogEntriesCache allKeysForObject:self.blogEntry];
            
            if (!keys.count) {
                
                [self close];
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
                    
                    // get blogEntry
                    NSUInteger lastIndex = [APIStore sharedStore].numberOfEntries.integerValue - 1;
                    _blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:[NSString stringWithFormat:@"%ld", lastIndex]];
                    
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
        
        NSArray *keys = [[APIStore sharedStore].blogEntriesCache allKeysForObject:_blogEntry];
        NSString *key = keys[0];
        
        // check what changed...
        NSMutableDictionary *changes = [[NSMutableDictionary alloc] init];
        
        if (![[_blogEntry valueForKey:@"title"] isEqualToString:title]) {
            
            [changes setObject:title
                        forKey:@"title"];
            
        }
        
        if (![[_blogEntry valueForKey:@"content"] isEqualToString:content]) {
            
            [changes setObject:content
                        forKey:@"content"];
            
        }
        
        // if changes occurred
        if (changes.allKeys.count != 0) {
            
            [[APIStore sharedStore] editEntry:key.integerValue changes:changes completion:^(NSError *error) {
                
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
            [[APIStore sharedStore] removeImageFromEntry:key.integerValue completion:^(NSError *error) {
                
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
    
    NSArray *keys = [[APIStore sharedStore].blogEntriesCache allKeysForObject:_blogEntry];
    NSString *key = keys[0];
    
    // upload new image
    [[APIStore sharedStore] setImageData:imageData forEntry:key.integerValue completion:^(NSError *error) {
        
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
