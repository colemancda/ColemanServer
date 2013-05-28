//
//  BlogEntryEditorViewController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/24/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntryEditorViewController.h"
#import "APIStore.h"

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
        
}

-(void)viewDidLoad
{
    // fetch that blog entry
    NSString *indexKey = [NSString stringWithFormat:@"%ld", self.blogEntryIndex];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    if (!blogEntry) {
        
        NSLog(@"You need to download the blog entry before you can edit it");
        
        [self popViewController];
        
    }
    
    // set the UI
    self.titleTextField.stringValue = [blogEntry valueForKey:@"title"];
    self.contentTextView.string = [blogEntry valueForKey:@"content"];
    
}

-(void)viewDidAppear
{
    
}

#pragma mark


- (IBAction)save:(id)sender {
    
    NSDictionary *changes = @{@"title": self.titleTextField.stringValue,
                              @"content" : self.contentTextView.string};
    
    [[APIStore sharedStore] editEntry:self.blogEntryIndex changes:changes completion:^(NSError *error) {
        
        if (error) {
            
            [NSApp presentError:error];
        }
        
        else {
            
            [self popViewController];
        }
        
    }];
    
    
}


@end
