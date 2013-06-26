//
//  HTTPMIMEDataResponse.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/25/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "HTTPMIMEDataResponse.h"

@implementation HTTPMIMEDataResponse

-(NSDictionary *)httpHeaders
{
    return @{@"Content-Types": [NSString stringWithFormat:@"%@", _mimeType]};
}

-(id)initWithData:(NSData *)dataArg
         mimeType:(NSString *)type
{
    self = [super initWithData:dataArg];
    
    if (self) {
        
        _mimeType = type;
        
    }
    
    return self;
}

@end
