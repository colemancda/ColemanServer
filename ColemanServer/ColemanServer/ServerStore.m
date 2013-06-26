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
#import "BlogStore.h"
#import "BlogEntry.h"
#import "NSString+Counter.h"
#import "User.h"
#import "UserStore.h"
#import "Token.h"
#import "MyHTTPConnection.h"

NSString *const kGETMethod = @"GET";

NSString *const kPOSTMethod = @"POST";

NSString *const kPUTMethod = @"PUT";

NSString *const kDELETEMethod = @"DELETE";

// UnAuthorized API

static NSString *kAPILoginURL = @"/login/:username/:password"; // GET

static NSString *kAPIBlogURL = @"/blog"; // GET

static NSString *kAPIEntryAtIndexURL = @"/blog/:index"; // GET

static NSString *kAPIImageForEntryAtIndexURL = @"/blog/:index/image"; // GET

// API with token

static NSString *kAPIBlogTokenURL = @"/blog/:token"; // POST

static NSString *kAPIEntryAtIndexTokenURL = @"/blog/:index/:token"; // PUT, DELETE

static NSString *kAPIImageForEntryAtIndexTokenURL = @"/blog/:index/image/:token"; // PUT, DELETE

// String Responses

static NSString *kAPIResponseServerError = @"Internal Server Error";

static NSString *kAPIResponseWrongUsernamePassword = @"Wrong Username / Password combination";

static NSString *kAPIResponseNoAccess = @"Access Forbidden";

static NSString *kAPIResponseInvalidToken = @"Invalid Token";

static NSString *kAPIResponseIndexBlogEntryIndex = @"Invalid Blog Entry Index";

@implementation UserStore (Token)

-(User *)userForToken:(NSString *)tokenStringValue
{
    if (!tokenStringValue) {
        return nil;
    }
    
    // find the user that token belongs to
    User *matchingUser;
    for (User *user in self.allUsers) {
        
        for (Token *token in user.tokens) {
            
            if ([token.stringValue isEqualToString:tokenStringValue]) {
                
                matchingUser = user;
                break;
                
            }
        }
        
        if (matchingUser) {
            break;
        }
    }
    
    return matchingUser;
}

@end

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
        
        // load user defaults
        self.prettyPrintJSON = [[NSUserDefaults standardUserDefaults] boolForKey:@"prettyPrintJSON"];
        
        // observe KVC
        [self addObserver:self
               forKeyPath:@"self.prettyPrintJSON"
                  options:NSKeyValueObservingOptionOld
                  context:nil];
        
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

#pragma mark - KVC

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    if ([keyPath isEqualToString:@"self.prettyPrintJSON"] &&
        object == self) {
        
        [[NSUserDefaults standardUserDefaults] setBool:self.prettyPrintJSON
                                                forKey:@"prettyPrintJSON"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
