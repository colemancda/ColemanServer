//
//  BlogEntryCell.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlogEntryCell : NSTableCellView

@property IBOutlet NSTextField *contentTextField;

@property IBOutlet NSTextField *dateTextField;

@property NSDateFormatter *dateFormatter;

-(void)showLoadedInfoWithTitle:(NSString *)title
                       content:(NSString *)content
                          date:(NSDate *)date;

-(void)showLoadedImage:(NSImage *)image;



@end
