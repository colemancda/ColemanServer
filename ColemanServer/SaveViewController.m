//
//  SaveViewController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "SaveViewController.h"
#import "SaveOption.h"
#import "SaveCell.h"

static NSString *SaveCellIdentifier = @"SaveCell";

@interface SaveViewController ()

@end

@implementation SaveViewController

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
        
        // register save cell
        [self.tableView registerNib:[[NSNib alloc] initWithNibNamed:@"SaveCell"
                                                             bundle:nil]
                      forIdentifier:SaveCellIdentifier];
        
        // saving options
        SaveOption *log = [[SaveOption alloc] init];
        log.name = @"Log";
        log.saveTarget = self;
        log.saveSelector = @selector(saveLog:);
        
        SaveOption *blog = [[SaveOption alloc] init];
        blog.name = @"Blog Entries";
        blog.saveTarget = self;
        blog.saveSelector = @selector(blogSave:);
        blog.backupTarget = self;
        blog.backupSelector = @selector(blogBackup:);
        
        SaveOption *users = [[SaveOption alloc] init];
        users.name = @"Users";
        users.saveTarget = self;
        users.saveSelector = @selector(usersSave:);
        users.backupTarget = self;
        users.backupSelector = @selector(usersBackup:);
        
        _saveOptions = @[log, blog, users];
    }
    
    return self;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.saveOptions.count;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    // get the model object for that view
    SaveOption *saveOption = self.saveOptions[row];
        
    // name column
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        
        NSTableCellView *cell = [[NSTableCellView alloc] initWithFrame:NSRectFromCGRect(CGRectZero)];
        cell.textField.stringValue = saveOption.name;
        
        return cell;
        
    }
    
    if ([tableColumn.identifier isEqualToString:@"save"]) {
        
        if (saveOption.saveTarget) {
            
            SaveCell *saveCell = [[SaveCell alloc] init];
            
            saveCell.saveButton.target = saveOption.saveTarget;
            [saveCell.saveButton setAction:saveOption.saveSelector];
            
        }
    }
    
    return nil;
}

-(void)saveLog:(id)sender
{
    
}

@end
