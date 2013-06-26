//
//  MyHTTPConnection.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "HTTPConnection.h"
@class HTTPDataResponse;

@interface MyHTTPConnection : HTTPConnection

+(NSString *)serverHeader;

+(NSNumberFormatter *)numberFormatter;

-(NSJSONWritingOptions)printJSONOption;

#pragma mark - Additional Error Handling

-(void)handleInternalError;


@end
