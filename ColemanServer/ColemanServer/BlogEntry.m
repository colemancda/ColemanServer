//
//  BlogEntry.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/5/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogEntry.h"


@implementation BlogEntry

@dynamic date;
@dynamic title;
@dynamic content;
@dynamic image;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set the current date
    self.date = [NSDate date];
}

@end
