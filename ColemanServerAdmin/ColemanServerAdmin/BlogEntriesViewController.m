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
#import "NSViewController+LoadingView.h"

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
                
                AppDelegate *appDelegate = [NSApp delegate];
                [appDelegate signOut];
                
            }
            else {
                
                // fetch all the entries
                for (NSInteger i = 0; i < [APIStore sharedStore].numberOfEntries.integerValue; i++) {
                    
                    // fetch all the info
                    [[APIStore sharedStore] fetchEntry:i completion:^(NSError *error) {
                       
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                            if (error) {
                                
                                [NSApp presentError:error];
                                
                                AppDelegate *appDelegate = [NSApp delegate];
                                [appDelegate signOut];
                                
                            }
                            else {
                                
                                // last object
                                if (i == [APIStore sharedStore].numberOfEntries.integerValue - 1) {
                                    
                                    [self.tableView reloadData];
                                    
                                }
                                
                            }
                            
                        }];
                        
                    }];
                    
                }
                
            }
            
        }];
        
    }];
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
    
    // get the blog entry
    NSString *indexKey = [NSString stringWithFormat:@"%ld", (long)row];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    if (blogEntry) {
        
        [cell showLoadedInfoWithTitle:[blogEntry valueForKey:@"title"]
                              content:[blogEntry valueForKey:@"content"]
                                 date:[blogEntry valueForKey:@"date"]];
    }
    
    return cell;
    
}

#pragma mark - NSTableView Delegate Protocol

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    NSString *indexKey = [NSString stringWithFormat:@"%ld", (long)row];
    NSManagedObject *blogEntry = [[APIStore sharedStore].blogEntriesCache objectForKey:indexKey];
    
    if (!blogEntry) {
        return NO;
    }
    
    return YES;
}


#pragma mark - NSTableView Notifications

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    
    if (tableView.selectedRow == -1) {
        
        self.canPerformAction = NO;
    }
    else {
        self.canPerformAction = YES;
    }
}

#pragma mark - Buttons

- (IBAction)createNewEntry:(id)sender {
    
    BlogEntryEditorViewController *editorVC = [[BlogEntryEditorViewController alloc] initWithNewEntry];
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    appDelegate.rootViewController = editorVC;
    
}

-(void)deleteEntry:(id)sender
{
    [[APIStore sharedStore] removeEntry:self.tableView.selectedRow completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [NSApp presentError:error];
                
                AppDelegate *appDelegate = [NSApp delegate];
                [appDelegate signOut];
            }
            
            else {
                
                [self.tableView reloadData];
            }
            
        }];
    }];
}

- (IBAction)editEntry:(id)sender {
    
    BlogEntryEditorViewController *editorVC = [[BlogEntryEditorViewController alloc] initWithEntry:self.tableView.selectedRow];
    
    AppDelegate *appDelegate = [NSApp delegate];
    appDelegate.rootViewController = editorVC;
}

@end
