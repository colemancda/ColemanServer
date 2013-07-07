//
//  EntriesWindowController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "APIStore.h"

@interface EntriesWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) IBOutlet NSTableView *tableView;

-(IBAction)createNewEntry:(id)sender;

-(IBAction)signOut:(id)sender;

@end
