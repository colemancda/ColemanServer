//
//  BlogEntryCell.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlogEntryCell : NSTableCellView

+(NSDateFormatter *)dateFormatter;

@property IBOutlet NSTextField *contentTextField;

@property IBOutlet NSTextField *dateTextField;

@property IBOutlet NSTextField *commentsTextField;

-(void)setNumberOfComments:(NSNumber *)numberOfComments;

-(void)setBlogEntry:(NSManagedObject *)blogEntry;

@end
