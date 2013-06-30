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

#pragma mark

-(void)showLoadedInfoWithTitle:(NSString *)title
                       content:(NSString *)content
                          date:(NSDate *)date
{
    // show the info text fields
    self.textField.stringValue = title;
    
    self.contentTextField.stringValue = content;
    
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    self.dateTextField.stringValue = dateString;    
}

@end
