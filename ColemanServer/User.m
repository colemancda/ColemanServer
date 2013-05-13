//
//  User.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "User.h"
#import "Token.h"
#import "UserStore.h"

@implementation User

@dynamic username;
@dynamic password;
@dynamic created;
@dynamic permissions;

#pragma mark - Initializations

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set date created
    self.created = [NSDate date];
    
    // initalize mutable array
    _tokens = [[NSMutableArray alloc] init];
    
}

#pragma mark - Properties

-(NSArray *)tokens
{
    return (NSArray *)_tokens;
}

#pragma mark

-(Token *)createToken
{
    // create new token
    Token *token = [[Token alloc] init];
    
    // delete any old tokens that have expired
    for (Token *oldToken in self.tokens) {
        
        // find the time interval since this was created
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:oldToken.created];
        
        // if the interval is more than allowed
        if (interval > [UserStore sharedStore].tokenDuration) {
            
            [_tokens removeObjectIdenticalTo:oldToken];
            
        }
    }
    
    // add to array
    [_tokens addObject:token];
    
    return token;
}

@end
