//
//  BlogEntryCell.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntryCell.h"
#import "APIStore.h"

@implementation BlogEntryCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    
    
}

-(void)setNumberOfComments:(NSNumber *)numberOfComments
{
    NSString *commentString = [NSString stringWithFormat:NSLocalizedString(@"%@ Comments", @"<number of comments> Comments"), numberOfComments];
    
    self.commentsButton.title = commentString;
}

@end
