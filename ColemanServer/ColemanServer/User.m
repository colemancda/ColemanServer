//
//  User.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/27/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "User.h"
#import "EntryComment.h"
#import "Token.h"


@implementation User

@dynamic created;
@dynamic password;
@dynamic permissions;
@dynamic username;
@dynamic comments;
@dynamic tokens;

#pragma mark - Initializations

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set date created
    self.created = [NSDate date];
}

@end
