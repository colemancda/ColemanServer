//
//  APIFunction.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/18/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

typedef NSObject<HTTPResponse> * (^APIResponse) (NSArray *);

@interface APIFunction : NSObject

@property NSString *path; // like /login/%@/%@

@property NSString *method;

@property (strong) APIResponse response;

@end
