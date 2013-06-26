//
//  ServerStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"

typedef NS_ENUM(NSInteger, ServerErrorCodes) {
    
    BadRequest = 400,
    Unauthorized,
    Forbidden = 403,
    NotFound,
    ServerError = 500
};

@interface ServerStore : NSObject
{
    HTTPServer *_server;
    NSDate *_dateServerStarted;
}

+ (ServerStore *)sharedStore;

@property (readonly) NSUInteger port;

@property (readonly) NSUInteger numberOfConnections;

@property (readonly) BOOL isRunning;

@property (readonly) NSTimeInterval serverUpTime;

@property BOOL prettyPrintJSON;

-(BOOL)startServerWithPort:(NSUInteger)port;

-(void)stopServer;


@end
