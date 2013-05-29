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

@property IBOutlet NSProgressIndicator *imageProgress;

@property IBOutlet NSProgressIndicator *infoProgress;

@property IBOutlet NSTextField *dateTextField;

@property NSDateFormatter *dateFormatter;

-(void)showLoadingUI;

-(void)showLoadedInfoWithTitle:(NSString *)title
                       content:(NSString *)content
                          date:(NSDate *)date;

-(void)showLoadedImage:(NSImage *)image;



@end
