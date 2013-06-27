//
//  EntryComment.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/27/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "EntryComment.h"
#import "BlogEntry.h"
#import "User.h"


@implementation EntryComment

@dynamic content;
@dynamic date;
@dynamic blogEntry;
@dynamic user;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set the current date
    self.date = [NSDate date];
}

@end
