//
//  ServerStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "ServerStore.h"
#import "HTTPServer.h"
#import "LogStore.h"
#import "BlogEntry.h"
#import "NSString+Counter.h"
#import "User.h"
#import "Token.h"
#import "MyHTTPConnection.h"

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
        
        NSLog(@"Initializing Server...");
        
        _server = [[HTTPServer alloc] init];
        
        _server.connectionClass = [MyHTTPConnection class];
        
    }
    return self;
}

#pragma mark

-(BOOL)startServerWithPort:(NSUInteger)port
{
    // log
    NSLog(@"Starting the HTTP server on port %ld...", (unsigned long)port);
    
    _server.port = port;
    
    NSError *error;
    
    BOOL success = [_server start:&error];
    
    if (!success) {
        
        [NSApp presentError:error];
        
        [[LogStore sharedStore] addError:error.localizedDescription];
    }
    
    // sucess!
    else {
        
        // set the start date
        _dateServerStarted = [NSDate date];
        
        // the port that was actually set (may be different if you set the port to 0)
        NSUInteger successfulPort = _server.listeningPort;
        
        // log
        NSString *logEntry = [NSString stringWithFormat:@"The server started successfully on port %ld", (unsigned long)successfulPort];
        
        [[LogStore sharedStore] addEntry:logEntry];
        
        // add port to user preferences
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:successfulPort]
                                                  forKey:@"port"];
        
        BOOL success = [[NSUserDefaults standardUserDefaults] synchronize];
        if (!success) {
            NSLog(@"Could not successfully set the new default port");
        }
        else {
            NSLog(@"Successfully set the new default port to %ld", (unsigned long)successfulPort);
        }
        
    }
    
    return success;
}

-(void)stopServer
{
    [_server stop];
    
    NSInteger numberOfConnections = self.numberOfConnections;
    
    NSString *uptime = [NSString counterStringFromSeconds:self.serverUpTime];
    
    NSString *stopServerLogEntry = [NSString stringWithFormat:@"Stopped server with %ld connections and %@ uptime", numberOfConnections, uptime];
    
    [[LogStore sharedStore] addEntry:stopServerLogEntry];
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

-(NSTimeInterval)serverUpTime
{
    return [[NSDate date] timeIntervalSinceDate:_dateServerStarted];
}

@end
