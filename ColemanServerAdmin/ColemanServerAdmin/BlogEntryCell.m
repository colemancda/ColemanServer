//
//  BlogEntryCell.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntryCell.h"
#import "APIStore.h"

static NSDateFormatter *dateFormatter;

@implementation BlogEntryCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
}

+(NSDateFormatter *)dateFormatter
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    }
    
    return dateFormatter;
}

-(void)setNumberOfComments:(NSNumber *)numberOfComments
{
    NSString *commentString = [NSString stringWithFormat:NSLocalizedString(@"%@ Comments", @"<number of comments> Comments"), numberOfComments];
    
    self.commentsButton.title = commentString;
}

-(void)setBlogEntry:(NSManagedObject *)blogEntry
{
    NSDate *date = [blogEntry valueForKey:@"date"];
    NSString *title = [blogEntry valueForKey:@"title"];
    NSString *content = [blogEntry valueForKey:@"content"];
    NSData *imageData = [blogEntry valueForKey:@"image"];
    
    // set date
    NSDateFormatter *dateFormatter = [self.class dateFormatter];
    NSString *dateString = [dateFormatter stringFromDate:date];
    self.dateTextField.stringValue = dateString;
    
    // title and content
    self.textField.stringValue = title;
    self.contentTextField.stringValue = content;
    
    // image...
    if (imageData) {
        self.imageView.image = [[NSImage alloc] initWithData:imageData];
    }
    if (imageData == nil) {
        
        // image need to be downloaded
        self.imageView.image = nil;
    }
    
}


@end
