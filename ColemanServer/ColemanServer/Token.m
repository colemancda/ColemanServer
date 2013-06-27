//
//  Token.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/27/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "Token.h"
#import "User.h"
#import "NSString+RandomString.h"

@implementation Token

@dynamic created;
@dynamic stringValue;
@dynamic user;

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // set the date it was created
    self.created = [NSDate date];
    
    // generate random token
    NSInteger length = [[NSUserDefaults standardUserDefaults] integerForKey:@"tokenLength"];
    self.stringValue = [NSString randomStringWithLength:length];
}

@end
