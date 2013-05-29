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
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithEntry:))];
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        
    }
    
    return self;
}

#pragma mark - 

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // fetch that blog entry
    NSString *indexKey = [NSString stringWithFormat:@"%ld", self.blogEntryIndex];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    if (!blogEntry) {
        
        NSLog(@"You need to download the blog entry before you can edit it");
        
        BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
        
        AppDelegate *appDelegate = [NSApp delegate];
        
        appDelegate.rootViewController = entriesVC;
        
    }
    
    // set the UI
    self.titleTextField.stringValue = [blogEntry valueForKey:@"title"];
    self.contentTextView.string = [blogEntry valueForKey:@"content"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    NSString *dateString = [dateFormatter stringFromDate:[blogEntry valueForKey:@"date"]];
    self.dateTextField.stringValue = dateString;
}

#pragma mark


- (IBAction)save:(id)sender {
    
    NSDictionary *changes = @{@"title": self.titleTextField.stringValue,
                              @"content" : self.contentTextView.string};
    
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


@end
