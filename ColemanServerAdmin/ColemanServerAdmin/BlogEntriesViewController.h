//
//  BlogEntriesViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/19/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PageViewController.h"

@interface BlogEntriesViewController : PageViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSBox *box;

@property (strong) IBOutlet NSTableView *tableView;

@property (strong) IBOutlet NSScrollView *tableViewScrollView;

#pragma mark - Loading View

@property (strong) IBOutlet NSView *loadingView;

@property (strong) IBOutlet NSProgressIndicator *loadingProgressIndicator;

#pragma mark - Zero Entries

@property (strong) IBOutlet NSView *zeroEntriesView;

#pragma mark - UI Change

-(void)showLoadingView;

-(void)showZeroEntriesView;

-(void)showTableView;

#pragma mark - Properties

@property NSNumber *numberOfEntries;

#pragma mark

- (IBAction)createNewEntry:(id)sender;

@end
