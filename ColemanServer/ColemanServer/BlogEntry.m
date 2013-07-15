//
//  BlogEntry.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/14/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntry.h"
#import "EntryComment.h"


@implementation BlogEntry

@dynamic content;
@dynamic date;
@dynamic image;
@dynamic title;
@dynamic comments;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set the current date
    self.date = [NSDate date];
}

@end
