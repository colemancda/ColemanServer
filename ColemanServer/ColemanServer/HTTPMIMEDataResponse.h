//
//  HTTPMIMEDataResponse.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/25/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "HTTPDataResponse.h"

@interface HTTPMIMEDataResponse : HTTPDataResponse
{
    NSString *_mimeType;
}

-(id)initWithData:(NSData *)data
         mimeType:(NSString *)type;

@end
