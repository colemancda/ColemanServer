//
//  BlogEntryEditorViewController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntryEditorViewController.h"
#import "APIStore.h"
#import "BlogEntriesViewController.h"
#import "AppDelegate.h"

@interface BlogEntryEditorViewController ()

@end

@implementation BlogEntryEditorViewController

- (id)initWithEntry:(NSUInteger)index
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
        _blogEntryIndex = index;
        _mode = ExistingEntry;
        
    }
    return self;
}

-(id)initWithNewEntry
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
        _mode = NewEntry;
        
    }
    return self;
}

-(id)init
{
    return self.initWithNewEntry;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        
    }
    
    return self;
}

#pragma mark

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    if (_mode == ExistingEntry) {
        
        // get the entry from the store
        NSString *indexKey = [NSString stringWithFormat:@"%ld", (long)self.blogEntryIndex];
        NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
        
        // set the UI
        self.titleTextField.stringValue = [blogEntry valueForKey:@"title"];
        self.contentTextView.string = [blogEntry valueForKey:@"content"];
        
        NSString *dateString = [dateFormatter stringFromDate:[blogEntry valueForKey:@"date"]];
        self.dateTextField.stringValue = dateString;
    }
    
    else {
        
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        self.dateTextField.stringValue = dateString;
        
    }
    
    
}

#pragma mark


- (IBAction)save:(id)sender {
    
    NSString *title = self.titleTextField.stringValue;
    NSString *content = self.contentTextView.string;
    
    // if new entry
    if (self.mode == NewEntry) {
        
        [[APIStore sharedStore] createEntryWithTitle:title content:content withCompletion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (error) {
                    
                    [NSApp presentError:error];
                    
                }
                
                BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
                
                AppDelegate *appDelegate = [NSApp delegate];
                appDelegate.rootViewController = entriesVC;
                
            }];
        }];
    }
    
    else {
        
        // get the blogEntry
        NSString *indexKey = [NSString stringWithFormat:@"%lu", self.blogEntryIndex];
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
        if (changes.allKeys.count == 0) {
            
            BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
            
            AppDelegate *appDelegate = [NSApp delegate];
            
            appDelegate.rootViewController = entriesVC;
            
            return;
        }
        
        [[APIStore sharedStore] editEntry:self.blogEntryIndex changes:changes completion:^(NSError *error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (error) {
                    
                    [NSApp presentError:error];
                }
                
                else {
                    
                    BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
                    
                    AppDelegate *appDelegate = [NSApp delegate];
                    
                    appDelegate.rootViewController = entriesVC;
                    
                }
                
            }];
            
        }];
        
    }
}

- (IBAction)cancel:(id)sender {
    
    BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
    AppDelegate *appDelegate = [NSApp delegate];
    appDelegate.rootViewController = entriesVC;
    
}


@end
