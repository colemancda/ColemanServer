//
//  MyHTTPConnection.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "HTTPConnection.h"
#import "MyHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPMessage.h"
#import "HTTPMIMEDataResponse.h"
#import "GCDAsyncSocket.h"
#import "ServerStore.h"
#import "NSString+isNonNegativeInteger.h"
#import "DataStore.h"
#import "User.h"
#import "BlogEntry.h"
#import "Token.h"
#import "LogStore.h"
#import "EntryComment.h"
#import "CertifcateStore.h"

static NSString *MimeTypeJSON = @"application/json";

// Define the various timeouts (in seconds) for various parts of the HTTP process
#define TIMEOUT_READ_FIRST_HEADER_LINE       30
#define TIMEOUT_READ_SUBSEQUENT_HEADER_LINE  30
#define TIMEOUT_READ_BODY                    -1
#define TIMEOUT_WRITE_HEAD                   30
#define TIMEOUT_WRITE_BODY                   -1
#define TIMEOUT_WRITE_ERROR                  30
#define TIMEOUT_NONCE                       300

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST_HEADER                10
#define HTTP_REQUEST_BODY                  11
#define HTTP_REQUEST_CHUNK_SIZE            12
#define HTTP_REQUEST_CHUNK_DATA            13
#define HTTP_REQUEST_CHUNK_TRAILER         14
#define HTTP_REQUEST_CHUNK_FOOTER          15
#define HTTP_PARTIAL_RESPONSE              20
#define HTTP_PARTIAL_RESPONSE_HEADER       21
#define HTTP_PARTIAL_RESPONSE_BODY         22
#define HTTP_CHUNKED_RESPONSE_HEADER       30
#define HTTP_CHUNKED_RESPONSE_BODY         31
#define HTTP_CHUNKED_RESPONSE_FOOTER       32
#define HTTP_PARTIAL_RANGE_RESPONSE_BODY   40
#define HTTP_PARTIAL_RANGES_RESPONSE_BODY  50
#define HTTP_RESPONSE                      90
#define HTTP_FINAL_RESPONSE                91

// HTTP Methods

#define HTTP_METHOD_GET             @"GET"
#define HTTP_METHOD_POST            @"POST"
#define HTTP_METHOD_PUT             @"PUT"
#define HTTP_METHOD_DELETE          @"DELETE"

static NSString *serverHeader;

@implementation MyHTTPConnection (Authorization)

-(User *)userForToken
{
    // get the authorization token
    NSString *tokenString = [request headerField:@"Authorization"];
    
    if (!tokenString) {
        
        return nil;
        
    }
    
    // search for token in DataStore
    Token *token = [[DataStore sharedStore] tokenWithStringValue:tokenString];
    
    // check if token was found
    if (!token) {
        
        return nil;
        
    }
    
    // get the user
    User *user = token.user;
    
    // warn if there is no user attached
    if (!user) {
        
        NSString *errorDescription = [NSString stringWithFormat:@"The token with '%@' string value and created at '%@' has no User object attached to it!", token.stringValue, token.created];
        
        [[LogStore sharedStore] addError:errorDescription];
        
        [self handleInternalError];
        
        return nil;
    }
    
    return user;
}

@end

@implementation MyHTTPConnection

-(NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method
                                             URI:(NSString *)path
{
    // handle '/'
    if ([path isEqualToString:@"/"]) {
        
        [self handleResourceNotFound];
        
        return nil;
    }
    
    // remove the '/' from the URI string
    path = [path substringFromIndex:1];
    
    // dissect the URI
    NSURL *url = [NSURL URLWithString:path];
    NSArray *pathComponents = [url pathComponents];
        
    ///////////////////
    // API FUNCTIONS
    ////////////////////
    
    // /login
    
    if ([pathComponents[0] isEqualToString:@"login"] &&
        pathComponents[0] == pathComponents.lastObject) {
        
#pragma mark GET /login
        
        // GET - Get authentication token
        if ([method isEqualToString:HTTP_METHOD_GET]) {
            
            // get authentication header
            NSString *authenticationString = [request headerField:@"Authorization"];
            
            if (!authenticationString) {
                
                [self handleAuthenticationFailed];
                
                return nil;
            }
            
            NSData *jsonDataAuthorization = [authenticationString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSDictionary *jsonObjectAuthorization = [NSJSONSerialization JSONObjectWithData:jsonDataAuthorization
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:nil];
            // check of not valid JSON
            if (!jsonObjectAuthorization || ![jsonObjectAuthorization isKindOfClass:[NSDictionary class]]) {
                
                [self handleAuthenticationFailed];
                return nil;
            }
            
            // check for username and password
            NSString *username = [jsonObjectAuthorization objectForKey:@"username"];
            
            NSString *password = [jsonObjectAuthorization objectForKey:@"password"];
            
            if (!username || !password) {
                
                [self handleAuthenticationFailed];
                
                return nil;
            }
            
            // find user for that username
            User *user = [[DataStore sharedStore] userForUsername:username];
            
            // if none is found
            if (!user) {
                
                [self handleAuthenticationFailed];
                
                return nil;
            }
            
            // compare passwords
            if (![user.password isEqualToString:password]) {
                
                [self handleAuthenticationFailed];
                
                return nil;
            }
            
            // create session token
            Token *token = [[DataStore sharedStore] createTokenForUser:user];
            
            // create JSON object
            NSDictionary *jsonObject = @{@"token": token.stringValue};
            
            // serialize JSON
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                               options:self.printJSONOption
                                                                 error:nil];
            // check for error
            if (!jsonData) {
                
                [self handleInternalError];
                
                return nil;
            }
            
            HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:jsonData
                                                                               mimeType:MimeTypeJSON];
            
            return response;
        }
        
#pragma mark POST /login
        // POST - Create new account
        if ([method isEqualToString:HTTP_METHOD_POST]) {
            
            // get JSON data body
            NSDictionary *jsonObjectAccountInfo = [NSJSONSerialization JSONObjectWithData:request.body
                                                                                  options:NSJSONReadingAllowFragments
                                                                                    error:nil];
            if (!jsonObjectAccountInfo || ![jsonObjectAccountInfo isKindOfClass:[NSDictionary class]]) {
                
                [self handleInvalidRequest:request.body];
                
                return nil;
            }
            
            // get the values
            NSString *username = [jsonObjectAccountInfo objectForKey:@"username"];
            NSString *password = [jsonObjectAccountInfo objectForKey:@"password"];
            
            // check if they are in the JSON Data
            if (!username || !password) {
                
                [self handleInvalidRequest:request.body];
                
                return nil;
                
            }
            
            // check if that username is available
            User *user = [[DataStore sharedStore] userForUsername:username];
            
            // if one already exists
            if (user) {
                
                [self handleForbidden];
                
                return nil;
            }
            
            // create new user
            user = [[DataStore sharedStore] createUser];
            
            // set the values
            user.username = username;
            user.password = password;
            
            // return success message
            NSString *message = [NSString stringWithFormat:@"Successfully created new user '%@'\n%@", username, [[self class] serverHeader]];
            
            NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
            
            HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
            
            return response;
            
        }
        
        // unsupported method
        [self handleUnknownMethod:method];
    }
    
    // /blog...
    /////////////
    if ([pathComponents[0] caseInsensitiveCompare:@"blog"] == NSOrderedSame) {
        
        // get number of entries
        NSInteger numberOfEntries = [DataStore sharedStore].allEntries.count;
        
        // only /blog
        if (pathComponents[0] == pathComponents.lastObject) {
            
#pragma mark GET /blog
            // GET - return the numer of blog entries
            if ([method isEqualToString:HTTP_METHOD_GET]) {
                
                // put togeather JSON dictionary
                NSDictionary *jsonObject = @{@"numberOfEntries": [NSNumber numberWithInteger:numberOfEntries]};
                
                // create JSON Data to export
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                   options:self.printJSONOption
                                                                     error:nil];
                // could not create JSON data, internal error
                if (!jsonData) {
                    
                    [self handleInternalError];
                    
                    return nil;
                }
                
                // return HTTP response
                HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:jsonData
                                                                                   mimeType:MimeTypeJSON];
                
                return response;
            }
            
#pragma mark POST /blog
            // POST - Create new entry
            if ([method isEqualToString:HTTP_METHOD_POST]) {
                
                // get user for token
                User *user = [self userForToken];
                
                if (!user) {
                    
                    [self handleAuthenticationFailed];
                    
                    return nil;
                    
                }
                
                // Check if the user is an admin
                if (user.permissions.integerValue != Admin) {
                    
                    [self handleForbidden];
                    
                    return nil;
                    
                }
                
                // check for attached JSON data
                NSDictionary *jsonObjectRequest = [NSJSONSerialization JSONObjectWithData:request.body
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:nil];
                // check for error
                if (!jsonObjectRequest || ![jsonObjectRequest isKindOfClass:[NSDictionary class]]) {
                    
                    [self handleInvalidRequest:request.body];
                    
                    return nil;
                    
                }
                
                // check for title and content
                NSString *title = [jsonObjectRequest objectForKey:@"title"];
                
                NSString *content = [jsonObjectRequest objectForKey:@"content"];
                
                if (!title || !content) {
                    
                    [self handleInvalidRequest:request.body];
                    
                    return nil;
                }
                
                // create new blog entry
                BlogEntry *entry = [[DataStore sharedStore] createEntry];
                entry.title = title;
                entry.content = content;
                
                // get the index of the entry
                NSUInteger index = [[DataStore sharedStore].allEntries indexOfObject:entry];
                
                // create JSON data to return
                NSDictionary *jsonObject = @{@"index": [NSNumber numberWithInteger:index]};
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                   options:self.printJSONOption
                                                                     error:nil];
                if (!jsonData) {
                    
                    [self handleInternalError];
                    
                    return nil;
                    
                }
                
                // create HTTP MIME response
                HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:jsonData
                                                                                   mimeType:MimeTypeJSON];
                
                return response;
            }
            
            [self handleUnknownMethod:method];
            
            return nil;
            
        }
        
        // /blog/#...
        if ([pathComponents[1] isNonNegativeInteger]) {
            
            // get the blog entry for that index...
            NSString *numberString = pathComponents[1];
            
            NSUInteger index = numberString.integerValue;
            
            // if no entries exist, then the request is invalid
            
            if (!numberOfEntries) {
                
                [self handleResourceNotFound];
                
                return nil;
                
            }
            
            // check if the index is invalid
            if (index >= numberOfEntries) {
                
                [self handleResourceNotFound];
                
                return nil;
            }
            
            // get the entry for that index
            BlogEntry *entry = [DataStore sharedStore].allEntries[index];
            
            // only /blog/#
            
            if (pathComponents[1] == pathComponents.lastObject) {
                
#pragma mark GET /blog/#
                // GET - Return the entry
                if ([method isEqualToString:HTTP_METHOD_GET]) {
                    
                    // put togeather JSON object
                    NSDictionary *jsonObject = @{@"title": entry.title,
                                                 @"content" : entry.content,
                                                 @"date" : [NSString stringWithFormat:@"%@", entry.date]};
                    
                    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                   options:self.printJSONOption
                                                                     error:nil];
                    
                    if (!data) {
                        
                        [self handleInternalError];
                        
                        return nil;
                        
                    }
                    
                    // create HTTP Response
                    HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:data  mimeType:MimeTypeJSON];
                    
                    return response;
                    
                }
                
                // check who is authorizing
                User *user = [self userForToken];
                
                // for any other methods than GET, you have to authorize as admin for this resource
                if (!user) {
                    
                    [self handleAuthenticationFailed];
                    
                    return nil;
                }
                
                if (user.permissions.integerValue != Admin) {
                    
                    [self handleForbidden];
                    
                    return nil;
                }
                
#pragma mark PUT /blog/#
                // PUT - Upload changes to entry
                
                if ([method isEqualToString:HTTP_METHOD_PUT]) {
                    
                    // check for JSON body
                    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:request.body
                                                                                   options:NSJSONReadingAllowFragments
                                                                                     error:nil];
                    
                    if (!jsonDictionary || ![jsonDictionary isKindOfClass:[NSDictionary class]]) {
                        
                        [self handleInvalidRequest:request.body];
                        
                        return nil;
                        
                    }
                    
                    NSString *title = [jsonDictionary objectForKey:@"title"];
                    
                    NSString *content = [jsonDictionary objectForKey:@"content"];
                    
                    // if no changes were uploaded
                    if (!title && !content) {
                        
                        [self handleInvalidRequest:request.body];
                        
                        return nil;
                        
                    }
                    
                    if (title) {
                        entry.title = title;
                    }
                    
                    if (content) {
                        entry.content = content;
                    }
                    
                    NSString *message = [NSString stringWithFormat:@"Successfully uploaded changes\n%@", [[self class ] serverHeader]];
                    
                    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                    
                    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
                    
                    return response;
                    
                }
                
#pragma mark DELETE /blog/#
                // DELETE - Delete entry
                if ([method isEqualToString:HTTP_METHOD_DELETE]) {
                    
                    [[DataStore sharedStore] removeEntry:entry];
                    
                    NSString *message = [NSString stringWithFormat:@"Successfully deleted Blog Entry %ld\n%@", (unsigned long)index, [[self class] serverHeader] ];
                    
                    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
                    
                    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:data];
                    
                    return response;
                }
                
            }
            
            // only /blog/#/photo
            if ([pathComponents[2] isEqualToString:@"photo"] &&
                pathComponents[2] == pathComponents.lastObject) {
                
#pragma mark GET /blog/#/photo
                // GET - return the Photo file
                if ([method isEqualToString:HTTP_METHOD_GET]) {
                    
                    NSData *imageData = entry.image;
                    
                    if (!imageData) {
                        
                        [self handleResourceNotFound];
                        
                        return nil;
                    }
                    
                    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:imageData];
                    
                    return response;
                    
                }
                
                // check who is authorizing
                User *user = [self userForToken];
                
                // for any other methods than GET, you have to authorize as admin for this resource
                if (!user) {
                    
                    [self handleAuthenticationFailed];
                    
                    return nil;
                }
                
                if (user.permissions.integerValue != Admin) {
                    
                    [self handleForbidden];
                    
                    return nil;
                }
                
#pragma mark PUT /blog/#/photo
                // PUT - Upload Photo
                if ([method isEqualToString:HTTP_METHOD_PUT]) {
                    
                    // check if the data is image data
                    NSImage *image = [[NSImage alloc] initWithData:request.body];
                    
                    if (!image) {
                        
                        [self handleInvalidRequest:request.body];
                        
                        return nil;
                    }
                    
                    entry.image = request.body;
                    
                    // return message
                    NSString *message = [NSString stringWithFormat:@"Successfully uploaded image data\n%@",  [[self class] serverHeader]];
                    
                    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                    
                    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
                    
                    return response;
                }
                
#pragma mark DELETE /blog/#/photo
                // Delete - Delete Photo
                if ([method isEqualToString:HTTP_METHOD_DELETE]) {
                    
                    entry.image = nil;
                    
                    // return message
                    
                    NSString *message = [NSString stringWithFormat:@"Successfully deleted photo\n%@", [[self class] serverHeader]];
                    
                    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                    
                    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
                    
                    return response;
                }
                
            }
            
            // /blog/#/comment...
            if ([pathComponents[2] isEqualToString:@"comment"]) {
                
                if (pathComponents[2] == pathComponents.lastObject) {
                    
#pragma mark GET /blog/#/comment

                    // GET - Number of comments
                    if ([method isEqualToString:HTTP_METHOD_GET]) {
                        
                        NSDictionary *jsonObject = @{@"numberOfComments": [NSNumber numberWithInteger:entry.comments.count]};
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                           options:self.printJSONOption
                                                                             error:nil];
                        
                        HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:jsonData mimeType:MimeTypeJSON];
                        
                        return response;
                    }
                    
                    // check for user
                    User *user = [self userForToken];
                    
                    if (!user) {
                        
                        [self handleAuthenticationFailed];
                        
                        return nil;
                    }
                    
                    
#pragma mark POST /blog/#/comment
                    
                    // POST - upload comment
                    if ([method isEqualToString:HTTP_METHOD_POST]) {
                        
                        // check for JSON data attatched
                        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                                                   options:NSJSONReadingAllowFragments
                                                                                     error:nil];
                        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
                            
                            [self handleInvalidRequest:request.body];
                            
                            return nil;
                            
                        }
                        
                        // get value
                        NSString *content = [jsonObject objectForKey:@"content"];
                        
                        // check if value was in JSON Data
                        if (!content) {
                            
                            [self handleInvalidRequest:request.body];
                            
                            return nil;
                            
                        }
                        
                        // create new comment
                        EntryComment *comment = [[DataStore sharedStore] createCommentForUser:user
                                                                               blogEntry:entry];
                        comment.content = content;
                        
                        // return success message
                        NSString *message = [NSString stringWithFormat:@"Successfully created new comment\n%@", [self.class serverHeader]];
                        
                        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                        
                        HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:messageData mimeType:MimeTypeJSON];
                        
                        return response;
                    }
                    
                    [self handleUnknownMethod:method];
                    
                    return nil;
                
                }
                
                // only /blog/#/comment/#
                if ([pathComponents[3] isNonNegativeInteger] && pathComponents[3] == pathComponents.lastObject)
                {
                    // validate the index...
                    NSString *commentIndexString = pathComponents[3];
                    NSUInteger commentIndex = commentIndexString.integerValue;
                    
                    // get the number of comments
                    NSUInteger numberOfComments = entry.comments.count;
                    
                    // if there are no comments
                    if (!numberOfComments) {
                        
                        [self handleResourceNotFound];
                        
                        return nil;
                    }
                    
                    // if the requested index is invalid
                    if (commentIndex >= numberOfComments) {
                        
                        [self handleResourceNotFound];
                        
                        return nil;
                    }
                    
                    // organize comments
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
                    NSArray *comments = [entry.comments.array sortedArrayUsingDescriptors:@[sortDescriptor]];
                    
                    // get comment
                    EntryComment *comment = comments[commentIndex];
                    

#pragma mark GET /blog/#/comment/#
                    
                    // GET
                    if ([method isEqualToString:HTTP_METHOD_GET]) {
                        
                        // make JSON data
                        NSDictionary *jsonObject = @{@"content": comment.content,
                                                     @"date" : [NSString stringWithFormat:@"%@", comment.date],
                                                     @"user" : comment.user.username};
                        
                        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                       options:self.printJSONOption
                                                                         error:nil];
                        
                        // make HTTP response
                        HTTPMIMEDataResponse *response = [[HTTPMIMEDataResponse alloc] initWithData:data mimeType:MimeTypeJSON];
                        
                        return response;
                        
                    }
                    
                    
                    // check for user
                    User *user = [self userForToken];
                    
                    if (!user) {
                        
                        [self handleAuthenticationFailed];
                        
                        return nil;
                    }
                    
                    // check if this is the same user that created the object or the admin
                    if (user != comment.user && user.permissions.integerValue != Admin) {
                        
                        [self  handleForbidden];
                        
                        return nil;
                    }
                    
#pragma mark PUT /blog/#/comment/#
                    // PUT - Edit comment
                    if ([method isEqualToString:HTTP_METHOD_PUT]) {
                        
                        // get JSON object
                        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body options:NSJSONReadingAllowFragments error:nil];
                        
                        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
                            
                            [self handleInvalidRequest:nil];
                            
                            return nil;
                            
                        }
                        
                        // get values
                        NSString *content = [jsonObject objectForKey:@"content"];
                        
                        if (!content) {
                            
                            [self handleInvalidRequest:nil];
                            
                            return nil;
                        }
                        
                        // upload value
                        comment.content = content;
                        
                        // return sucess message
                        NSString *message = [NSString stringWithFormat:@"Successfully changed comment\n%@", [self.class serverHeader]];
                        
                        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                        
                        HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
                        
                        return response;
                    }
                    
#pragma mark DELETE /blog/#/comment/#
                    if ([method isEqualToString:HTTP_METHOD_DELETE]) {
                        
                        // delete comment
                        [[DataStore sharedStore] removeComment:comment];
                        
                        // return success message
                        NSString *message = [NSString stringWithFormat:@"Successfully deleted comment\n%@", [self.class serverHeader]];
                        
                        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                        
                        HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:messageData];
                        
                        return response;
                    }
                    
                    [self handleUnknownMethod:method];
                    
                    return nil;
                }
                
            }
        }
    }
    
    // if none of the API functions were called, then return 404
    [self handleResourceNotFound];
    
    return nil;
    
}

#pragma mark - Pretty Print JSON Option

-(NSJSONWritingOptions)printJSONOption
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"prettyPrintJSON"]) {
        
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

#pragma mark - ServerName String

+(NSString *)serverHeader
{
    if (!serverHeader) {
        
        // Set a default Server header in the form of YourApp/1.0
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
        if (!appVersion) {
            appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
        }
        serverHeader = [NSString stringWithFormat:@"%@/%@",
                                  [bundleInfo objectForKey:@"CFBundleName"],
                                  appVersion];
    }
    
    return serverHeader;
}

#pragma mark - Headers

/**
 * This method is called immediately prior to sending the response headers.
 * This method adds standard header fields, and then converts the response to an NSData object.
 **/
- (NSData *)preprocessResponse:(HTTPMessage *)response
{
	// Override me to customize the response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessResponse:response]
    
    [self setupCommonHTTPHeadersForResponse:response];
    
    return [super preprocessResponse:response];
}

/**
 * This method is called immediately prior to sending the response headers (for an error).
 * This method adds standard header fields, and then converts the response to an NSData object.
 **/
- (NSData *)preprocessErrorResponse:(HTTPMessage *)response
{	
	// Override me to customize the error response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessErrorResponse:response]
	//
	// Notes:
	// You can use [response statusCode] to get the type of error.
	// You can use [response setBody:data] to add an optional HTML body.
	// If you add a body, don't forget to update the Content-Length.
	//
	// if ([response statusCode] == 404)
	// {
	//     NSString *msg = @"<html><body>Error 404 - Not Found</body></html>";
	//     NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	//
	//     [response setBody:msgData];
	//
	//     NSString *contentLengthStr = [NSString stringWithFormat:@"%lu", (unsigned long)[msgData length]];
	//     [response setHeaderField:@"Content-Length" value:contentLengthStr];
	// }
    
    // add html message
    NSString *errorPageHTML = [NSString stringWithFormat:@"Error %ld \n\n%@", (long)[response statusCode], [self.class serverHeader]];
    [response setBody:[errorPageHTML dataUsingEncoding:NSUTF8StringEncoding]];
    
    // update content length
    NSString *contentLengthStr = [NSString stringWithFormat:@"%lu", (unsigned long)[response.body length]];
	[response setHeaderField:@"Content-Length" value:contentLengthStr];
    
    // setup common headers
    [self setupCommonHTTPHeadersForResponse:response];
	
    return [super preprocessErrorResponse:response];
}

-(void)setupCommonHTTPHeadersForResponse:(HTTPMessage *)response
{
    // HTTP Server header
    [response setHeaderField:@"Server" value:[MyHTTPConnection serverHeader]];
    
}

#pragma mark - Additional Error Handling

-(void)handleInternalError
{
    // Status Code 500 - Server Error
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:500
                                                                description:nil
                                                                    version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
    
}

-(void)handleForbidden
{
    // Status Code 403 - Forbidden
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:403
                                                                description:nil
                                                                    version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
    
}

#pragma mark

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    return YES;
}

-(void)processBodyData:(NSData *)postDataChunk
{
    [request appendData:postDataChunk];
}

#pragma mark - HTTPS

-(BOOL)isSecureServer
{
    return [[CertifcateStore sharedStore] fileExists];
}

-(NSArray *)sslIdentityAndCertificates
{
    if (!self.isSecureServer) {
        return nil;
    }
    
    if (!_certificates) {
        
        NSData *certificateData = [NSData dataWithContentsOfFile:[CertifcateStore sharedStore].filePath];
        
        SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certificateData));
        
        SecIdentityRef identity;
        
        SecIdentityCreateWithCertificate(NULL, certificate, &identity);
        
        _certificates = @[(__bridge id)identity];
        
        CFRelease(certificate);
        CFRelease(identity);
        
    }
    
    return _certificates;
}

@end
