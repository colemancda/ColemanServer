//
//  BlogEntryCell.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntryCell.h"

@implementation BlogEntryCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // initialize date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    
}

-(void)editEntry:(id)sender
{
    
}

-(void)deleteEntry:(id)sender
{
    
    
}

@end
