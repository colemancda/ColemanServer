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
    
    // show progress indicators
    [self showLoadingUI];
    
    // initialize date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    
}

#pragma mark

-(void)showLoadingUI
{
    // hide the views
    NSArray *viewsToHide = @[self.contentTextField, self.textField, self.imageView, self.dateTextField];
    for (NSView *viewToHide in viewsToHide) {
        [viewToHide setHidden:YES];
    }
    
    // start animating the progress indicators
    NSArray *progressIndicators = @[self.imageProgress, self.infoProgress];
    for (NSProgressIndicator *progressIndicator in progressIndicators) {
        [progressIndicator setHidden:NO];
        [progressIndicator startAnimation:nil];
    }
}

-(void)showLoadedInfoWithTitle:(NSString *)title
                       content:(NSString *)content
                          date:(NSDate *)date
{
    // stop the progress indicator
    [self.infoProgress stopAnimation:nil];
    [self.infoProgress setHidden:YES];
    
    // show the info text fields
    self.textField.stringValue = title;
    [self.textField setHidden:NO];
    
    self.contentTextField.stringValue = content;
    [self.contentTextField setHidden:NO];
    
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    self.dateTextField.stringValue = dateString;
    [self.dateTextField setHidden:NO];
    
}

@end
