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
#import "User.h"
#import "UserStore.h"
#import "Token.h"

// UnAuthorized API

static NSString *kAPILoginURL = @"/login/:username/:password"; // GET

static NSString *kAPIBlogURL = @"/blog"; // GET

static NSString *kAPIEntryAtIndexURL = @"/blog/:index"; // GET

// API with token

static NSString *kAPIBlogTokenURL = @"/blog/:token"; // POST

static NSString *kAPIEntryAtIndexTokenURL = @"/blog/:index/:token"; // PUT, DELETE

// String Responses

static NSString *kAPIResponseServerError = @"Internal Server Error";

static NSString *kAPIResponseWrongUsernamePassword = @"Wrong Username / Password combination";

static NSString *kAPIResponseNoAccess = @"Access Forbidden";

static NSString *kAPIResponseInvalidToken = @"Invalid Token";

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
        
#pragma mark - API Blocks
        
        // setup response code //
        
#pragma mark numberOfEntries
        
        // numberOfEntries...
        [_server handleMethod:kGETMethod withPath:kAPIBlogURL block:^(RouteRequest *request, RouteResponse *response) {
            
            // get the data from the store
            
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            NSDictionary *jsonObject = @{@"entries": [NSNumber numberWithInteger:count]};
            
            NSError *jsonSerializationError;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&jsonSerializationError];
            if (!jsonData) {
                
                // error in json serialization...
                
                NSString *errorString = [NSString stringWithFormat:@"Could not serialize JSON object. %@", jsonSerializationError.localizedDescription];
                
                // log
                [[LogStore sharedStore] addError:errorString];
                [response setStatusCode:500];
                [response respondWithString:kAPIResponseServerError];
                
            }
            
            [response respondWithData:jsonData];
            
        }];
        
#pragma mark Entry At Index
        
        // entry at index
        [_server handleMethod:kGETMethod withPath:kAPIEntryAtIndexURL block:^(RouteRequest *request, RouteResponse *response) {
            
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            // no objects in array
            if (!count) {
                
                response.statusCode = 404;
                [response respondWithString:@"No entries exist on the server"];
                return;
                
            }
            
            // get the index
            NSString *indexString = [request.params objectForKey:@"index"];
            NSUInteger index = indexString.integerValue;
            
            // check if index is valid
            if (index >= count) {
                
                response.statusCode = 400;
                [response respondWithString:@"Invalid index"];
                return;
            }
            
            // get blog entry
            BlogEntry *blogEntry = [[BlogStore sharedStore].allEntries objectAtIndex:index];
            
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
                
                NSString *errorString = [NSString stringWithFormat:@"Could not serialize Blog Entry into JSON data. %@", jsonSerializationError];
                
                [[LogStore sharedStore] addError:errorString];
                
                response.statusCode = 500;
                [response respondWithString:kAPIResponseServerError];
                
            }
            
            else {
                
                [response respondWithData:jsonData];
                
            }
            
        }];
        
#pragma mark Login
        // login...
        [_server handleMethod:kGETMethod withPath:kAPILoginURL block:^(RouteRequest *request, RouteResponse *response) {
            
            // find user with that username
            NSString *username = [request.params objectForKey:@"username"];
            
            // lowercase the given username
            username = username.lowercaseString;
            
            // search for a user with that username
            User *matchingUser;
            for (User *user in [UserStore sharedStore].allUsers) {
                
                if ([user.username isEqualToString:username]) {
                    
                    matchingUser = user;
                    
                    break;
                }
            }
            
            // no user exists for that username
            if (!matchingUser) {
                
                response.statusCode = 401;
                [response respondWithString:kAPIResponseWrongUsernamePassword];
                
                return;
            }
            
            // compare password
            NSString *password = request.params[@"password"];
            
            // if the password is incorrect
            if (![matchingUser.password isEqualToString:password])
            {
                
                response.statusCode = 401;
                [response respondWithString:kAPIResponseWrongUsernamePassword];
                
                return;
            }
            
            // create json object to return
            else {
                
                // create token
                Token *token = [matchingUser createToken];
                
                // create json object
                NSDictionary *jsonObject = @{@"token": token.stringValue};
                
                NSError *jsonSerializationError;
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&jsonSerializationError];
                if (!jsonData) {
                    
                    // log
                    NSString *logError = [NSString stringWithFormat:@"Could not serialize token into JSON data. %@", jsonSerializationError.localizedDescription];
                    
                    [[LogStore sharedStore] addError:logError];
                    
                    // respond with error
                    response.statusCode = 500;
                    [response respondWithString:kAPIResponseServerError];
                    
                    return;
                }
                
                // success!
                else {
                    
                    [response respondWithData:jsonData];
                    return;
                }
            }
            
        }];
        
#pragma mark Add Blog Entry
        
        // add blog entry...
        [_server handleMethod:kPOSTMethod withPath:kAPIBlogTokenURL block:^(RouteRequest *request, RouteResponse *response) {
            
            NSString *tokenStringValue = [request.params objectForKey:@"token"];
            
            User *user = [[UserStore sharedStore] userForToken:tokenStringValue];
            
            // if the token was not found
            if (!user) {
                
                response.statusCode = 401;
                [response respondWithString:kAPIResponseInvalidToken];
                return;
            }
            
            // if the user does not have access
            if (user.permissions.integerValue != Admin) {
                
                response.statusCode = 403;
                [response respondWithString:kAPIResponseNoAccess];
                return;
            }
            
            // create new entry
            BlogEntry *entry = [[BlogStore sharedStore] createEntry];
            
            NSInteger entryIndex = [[BlogStore sharedStore].allEntries indexOfObject:entry];
            
            NSNumber *entryIndexNumber = [NSNumber numberWithInteger:entryIndex];
            
            // create JSON Data to send
            NSDictionary *jsonObject = @{@"index": entryIndexNumber};
            
            NSError *jsonError;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&jsonError];
            
            if (!jsonData) {
                
                NSString *errorEntry = [NSString stringWithFormat:@"Could not serialize token into JSON data. %@", jsonError.localizedDescription];
                
                [[LogStore sharedStore] addError:errorEntry];
                
                response.statusCode = 500;
                [response respondWithString:kAPIResponseServerError];
                
                return;
            }
            
            // success
            
            [response respondWithData:jsonData];
            
            return;
            
        }];
        
#pragma mark Edit Blog Entry
        
        // edit blog entry...
        [_server handleMethod:kPUTMethod withPath:kAPIEntryAtIndexTokenURL block:^(RouteRequest *request, RouteResponse *response) {
            
            NSString *tokenStringValue = [request.params objectForKey:@"token"];
            
            User *user = [[UserStore sharedStore] userForToken:tokenStringValue];
            
            // if the token was not found
            if (!user) {
                
                response.statusCode = 401;
                [response respondWithString:kAPIResponseInvalidToken];
                return;
            }
            
            // if the user does not have access
            if (user.permissions.integerValue != Admin) {
                
                response.statusCode = 403;
                [response respondWithString:kAPIResponseNoAccess];
                return;
            }
            
            // get the number of blog entries
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            // no objects in array
            if (!count) {
                
                response.statusCode = 404;
                [response respondWithString:@"No entries exist on the server"];
                return;
                
            }
            
            // get the index
            NSString *indexString = [request.params objectForKey:@"index"];
            NSUInteger index = indexString.integerValue;
            
            // check if index is valid
            if (index >= count) {
                
                response.statusCode = 400;
                [response respondWithString:@"No entries for that value"];

                return;
            }
            
            // get blog entry
            BlogEntry *blogEntry = [[BlogStore sharedStore].allEntries objectAtIndex:index];
            
            NSData *httpBodyData = request.body;
            
            if (!httpBodyData) {
                
                response.statusCode = 400;
                [response respondWithString:@"You need to send data"];

                return;
                
            }
            
            NSError *jsonError;
            
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:httpBodyData options:NSJSONReadingAllowFragments error:&jsonError];
            
            // the data recieved is not JSON
            if (!jsonObject) {
                
                response.statusCode = 400;
                NSString *responseString = [NSString stringWithFormat:@"Could not parse JSON data sent"];
                [response respondWithString:responseString];
                
                return;
            }
            
            // JSON data recieved is not JSON
            if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = 400;
                NSString *responseString = [NSString stringWithFormat:@"Wrong JSON data sent"];
                [response respondWithString:responseString];
                
                return;
            }
            
            // if the JSON dictionary has a 'title' value, then change the title of the blog entry
            NSString *title = [jsonObject objectForKey:@"title"];
            
            if (title) {
                
                blogEntry.title = title;
            }
            
            // if we got a value for 'content', then set it
            NSString *content = [jsonObject objectForKey:@"content"];
            
            if (content) {
                
                blogEntry.content = content;
            }
            
            // respond
            
            [response respondWithString:@"Succesfully made the changes"];
            
        }];
        
        
#pragma mark Remove Blog Entry
        
        // remove blog entry
        [_server handleMethod:kDELETEMethod withPath:kAPIEntryAtIndexTokenURL block:^(RouteRequest *request, RouteResponse *response) {
            
            NSString *tokenStringValue = [request.params objectForKey:@"token"];
            
            User *user = [[UserStore sharedStore] userForToken:tokenStringValue];
            
            // if the token was not found
            if (!user) {
                
                response.statusCode = 401;
                [response respondWithString:kAPIResponseInvalidToken];
                return;
            }
            
            // if the user does not have access
            if (user.permissions.integerValue != Admin) {
                
                response.statusCode = 403;
                [response respondWithString:kAPIResponseNoAccess];
                return;
            }
            
            // get the number of blog entries
            NSUInteger count = [BlogStore sharedStore].allEntries.count;
            
            // no objects in array
            if (!count) {
                
                response.statusCode = 404;
                
                [response respondWithString:@"No entries exist on the server"];
                return;
                
            }
            
            // get the index
            NSString *indexString = [request.params objectForKey:@"index"];
            NSUInteger index = indexString.integerValue;
            
            // check if index is valid
            if (index >= count) {
                
                response.statusCode = 400;
                [response respondWithString:@"No entries for that value"];
                
                return;
            }
            
            // get blog entry
            BlogEntry *blogEntry = [[BlogStore sharedStore].allEntries objectAtIndex:index];
            
            // remove blog entry
            [[BlogStore sharedStore] removeEntry:blogEntry];
            [response respondWithString:@"Successfully removed blog entry"];
            
        }];
        
                
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
