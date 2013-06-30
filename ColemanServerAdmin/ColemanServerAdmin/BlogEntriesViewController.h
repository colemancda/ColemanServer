//
//  BlogEntriesViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/19/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlogEntriesViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSTableView *tableView;

@property (strong) IBOutlet NSScrollView *tableViewScrollView;

@property BOOL canPerformAction;

#pragma mark

- (IBAction)createNewEntry:(id)sender;

- (IBAction)deleteEntry:(id)sender;

- (IBAction)editEntry:(id)sender;


@end
