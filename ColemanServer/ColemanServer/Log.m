//
//  Log.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "Log.h"

@implementation Log

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        
        // set the string
        _string = string;
        
        // set the time this was initialized
        _date = [NSDate date];
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithString:))];
    return nil;
}

@end
