//
//  Token.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/10/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "Token.h"
#import "NSString+RandomString.h"

@implementation Token

-(id)init
{
    self = [super init];
    if (self) {
        
        // set the date it was created
        _created = [NSDate date];
        
        // generate random token
        NSInteger length = [[NSUserDefaults standardUserDefaults] integerForKey:@"tokenLength"];
        _stringValue = [NSString randomStringWithLength:length];
        
    }
    return self;
    
}



@end
