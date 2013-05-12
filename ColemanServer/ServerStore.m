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
#import "BlogStore.h"
#import "BlogEntry.h"
#import "NSString+Counter.h"

static NSString *kAPINumberOfEntriesURL = @"/blog/numberOfEntries";

static NSString *kAPIEntryAtNumberURL = @"/blog/entry/:number";

static NSString *kAPILoginURL = @"/blog/login/:user/:password";


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
        
        // numberOfEntries...
        [_server handleMethod:kGETMethod withPath:kAPINumberOfEntriesURL block:^(RouteRequest *request, RouteResponse *response) {
            
            // get the data from the store
            
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            NSDictionary *jsonObject = @{@"numberOfEntries": [NSNumber numberWithInteger:count]};
            
            NSError *jsonSerializationError;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&jsonSerializationError];
            if (!jsonData) {
                
                // error in json serialization...
                
                NSString *errorString = [NSString stringWithFormat:@"Could not serialize JSON object. %@", jsonSerializationError.localizedDescription];
                
                // log
                [[LogStore sharedStore] addError:errorString];
                
                [response respondWithString:@"Error"];
                
            }
            
            [response respondWithData:jsonData];
            
        }];
        
        // entryAtNumber: ...
        [_server handleMethod:kGETMethod withPath:kAPIEntryAtNumberURL block:^(RouteRequest *request, RouteResponse *response) {
            
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            // no objects in array
            if (!count) {
                
                [response respondWithString:@"No entries exist on the server"];
                return;
                
            }
            
            // get the index
            NSString *indexString = [request.params objectForKey:@"number"];
            
            NSInteger number = indexString.integerValue;
            
            if (!number || number > count) {
                
                [response respondWithString:@"No entries for that value"];
                return;
            }
            
            BlogEntry *blogEntry = [[BlogStore sharedStore].allEntries objectAtIndex:number - 1];
            
            // create strings
            
            NSString *dateString = [NSString stringWithFormat:@"%@", blogEntry.date];
            
            NSString *titleString;
            
            if (blogEntry.title) {
                
                titleString = [NSString stringWithFormat:@"%@", blogEntry.title];
                
            }
            else {
                titleString = @"";
            }
            
            NSString *contentString;
            
            if (blogEntry.content) {
                
                contentString = [NSString stringWithFormat:@"%@", blogEntry.content];
                
            }
            else {
                contentString = @"";
            }
            
            
            // create json object
            
            NSDictionary *jsonObject = @{@"date": dateString,
                                         @"title": titleString,
                                         @"content" : contentString};
            
            NSError *jsonSerializationError;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&jsonSerializationError];
            
            if (!jsonData) {
                
                NSString *errorString = [NSString stringWithFormat:@"Could not serialize Blog Entry into JSON object. %@", jsonSerializationError];
                
                [[LogStore sharedStore] addError:errorString];
                
                [response respondWithString:@"Error fetching Blog Entry"];
                
            }
            
            else {
                
                [response respondWithData:jsonData];
                
            }
            
        }];
        
        [_server handleMethod:kGETMethod withPath:kAPILoginURL block:^(RouteRequest *request, RouteResponse *response) {
            
            // verify the username
            
            
            
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
        
        // set the start date
        _dateServerStarted = [NSDate date];
        
        // log
        NSString *logEntry = [NSString stringWithFormat:@"The server started successfully on port %d", _server.listeningPort];
        
        [[LogStore sharedStore] addEntry:logEntry];
        
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
