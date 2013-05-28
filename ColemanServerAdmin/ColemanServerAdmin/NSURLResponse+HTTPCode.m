//
//  NSURLResponse+HTTPCode.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "NSURLResponse+HTTPCode.h"

@implementation NSURLResponse (HTTPCode)

-(NSNumber *)httpCode
{
    if (![self isKindOfClass:[NSHTTPURLResponse class]]) {
        return nil;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self;
    
    return [NSNumber numberWithInteger:httpResponse.statusCode];
}

@end
