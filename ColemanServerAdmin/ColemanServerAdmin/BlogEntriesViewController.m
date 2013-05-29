//
//  BlogEntriesViewController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/19/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntriesViewController.h"
#import "BlogEntryCell.h"
#import "APIStore.h"
#import "BlogEntryEditorViewController.h"
#import "AppDelegate.h"

static NSString *CellIdentifier = @"BlogEntryCell";

@interface BlogEntriesViewController ()

@end

@implementation BlogEntriesViewController

- (id)init
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // try fo fetch number of entries
    
    [[APIStore sharedStore] fetchNumberOfEntriesWithCompletion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error];
                
            }
            else {
                
                [self.tableView reloadData];
                
                [self showTableView];
                
                // if there are zero entries
                if (![APIStore sharedStore].numberOfEntries.integerValue) {
                    
                    [self showZeroEntriesView];
                    
                }
                
            }
            
        }];
        
    }];
}

#pragma mark - UI Change

-(void)showLoadingView
{
    self.box.contentView = self.loadingView;
    
    [self.loadingProgressIndicator startAnimation:nil];
    
}

-(void)showZeroEntriesView
{
    self.box.contentView = self.zeroEntriesView;
}

-(void)showTableView
{
    self.box.contentView = self.tableViewScrollView;
    
}

#pragma mark - NSTableView DataSource Protocol

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [APIStore sharedStore].numberOfEntries.integerValue;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    BlogEntryCell *cell = [tableView makeViewWithIdentifier:CellIdentifier
                                                        owner:self];
    
    // fetch blog entry
    [[APIStore sharedStore] fetchEntry:row completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error];
            }
            
            else {
                
                // get the blog entry
                NSString *indexKey = [NSString stringWithFormat:@"%ld", row];
                NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
                
                [cell showLoadedInfoWithTitle:[blogEntry valueForKey:@"title"]
                                      content:[blogEntry valueForKey:@"content"]
                                         date:[blogEntry valueForKey:@"date"]];
                
            }
            
        }];
        
    }];
    
    
    return cell;
    
}

#pragma mark - NSTableView Delegate Protocol

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    // get the index
    NSTableView *tableView = notification.object;
    
    NSUInteger index = tableView.selectedRow;
    
    BlogEntryEditorViewController *editorVC = [[BlogEntryEditorViewController alloc] initWithEntry:index];
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    appDelegate.rootViewController = editorVC;
}


#pragma mark - Buttons

- (IBAction)createNewEntry:(id)sender {
    
    // ask the API to create a new entry
    
    [[APIStore sharedStore] createEntryWithCompletion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error];
                
            }
            else {
                
                // get the index of the last object
                NSUInteger index = [APIStore sharedStore].blogEntriesCache.allKeys.count - 1;
                
                BlogEntryEditorViewController *editorVC = [[BlogEntryEditorViewController alloc] initWithEntry:index];
                
                AppDelegate *appDelegate = [NSApp delegate];
                
                appDelegate.rootViewController = editorVC;
            }
            
        }];
        
    }];
    
}


@end
