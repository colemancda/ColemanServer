//
//  ServerStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "ServerStore.h"
#import "HTTPServer.h"
#import "RoutingHTTPServer.h"
#import "LogStore.h"

static NSString *kAPINumberOfEntries = @"/blog/numberOfPosts";

static NSString *kAPIEntryForIndex = @"/blog/post/:index";


@implementation ServerStore

+ (ServerStore *)sharedStore
{
    static ServerStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        _server = [[RoutingHTTPServer alloc] init];
        
        // Set a default Server header in the form of YourApp/1.0
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
        if (!appVersion) {
            appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
        }
        NSString *serverHeader = [NSString stringWithFormat:@"%@/%@",
                                  [bundleInfo objectForKey:@"CFBundleName"],
                                  appVersion];
        
        [_server setDefaultHeader:@"Server" value:serverHeader];
        
        // setup response code
        
        [_server handleMethod:kGETMethod withPath:kAPINumberOfEntries block:^(RouteRequest *request, RouteResponse *response) {
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"numberOfPosts": @100} options:NSJSONWritingPrettyPrinted error:nil];
            
            [response respondWithData:jsonData];
            
        }];
        
        [_server handleMethod:kGETMethod withPath:kAPIEntryForIndex block:^(RouteRequest *request, RouteResponse *response) {
            
            NSString *index = [request.params objectForKey:@"index"];
            
            [response respondWithString:index];
            
        }];
                
    }
    return self;
}

#pragma mark

-(BOOL)startServerWithPort:(NSUInteger)port
{
    // log
    [[LogStore sharedStore] addEntry:[NSString stringWithFormat:@"Starting the HTTP server on port %ld", (unsigned long)port]];
    
    _server.port = port;
    
    NSError *error;
    
    BOOL success = [_server start:&error];
    
    if (!success) {
        
        [NSApp presentError:error];
        
        [[LogStore sharedStore] addError:error.localizedDescription];
    }
    
    // sucess!
    else {
        
        // log
        NSString *logEntry = [NSString stringWithFormat:@"The server started successfully on port %d", _server.listeningPort];
        
        [[LogStore sharedStore] addEntry:logEntry];
        
    }
    
    return success;
}

-(void)stopServer
{
    
    [_server stop];
    
    [[LogStore sharedStore] addEntry:@"Stopped server"];
}

#pragma mark - Properties

-(NSUInteger)port
{
    return _server.listeningPort;
}

-(NSUInteger)numberOfConnections
{
    return _server.numberOfHTTPConnections;
}

-(BOOL)isRunning
{
    return _server.isRunning;
}

@end
