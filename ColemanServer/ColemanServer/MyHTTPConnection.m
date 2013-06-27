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
    NSArray *pathComponents = [path pathComponents];
    
    ///////////////////
    // API FUNCTIONS
    ////////////////////
    
    // /login
    
    if ([pathComponents[0] isEqualToString:@"login"] &&
        pathComponents[0] == pathComponents.lastObject) {
        
        // get authentication header
        NSString *authenticationString = [request headerField:@"Authorization"];
        
        NSData *jsonData = [authenticationString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
        // check of not valid JSON
        if (!jsonObject || [jsonObject isKindOfClass:[NSDictionary class]]) {
            
            [self handleAuthenticationFailed];
            
        }
        
        // check for username and password
        NSString *username = [jsonObject objectForKey:@"username"];
        
        NSString *password = [jsonObject objectForKey:@"password"];
        
        
        
    }
    
    // /blog...
    /////////////
    if ([pathComponents[0] caseInsensitiveCompare:@"blog"] == NSOrderedSame) {
        
        // get number of entries
        NSInteger numberOfEntries = [DataStore sharedStore].allEntries.count;
        
        // only /blog
        if (pathComponents[0] == pathComponents.lastObject) {
            
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
            
            // POST - Create new entry
        
            if ([method isEqualToString:HTTP_METHOD_POST]) {
            
            // check for authentication header
            // [request headerField:]
            
            }
            
        }

        // /blog/#...
        
        if ([pathComponents[1] isNonNegativeInteger]) {
            
            // get the blog entry for that index
            
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
                
                // GET - Return the entry
                
                if ([method isEqualToString:HTTP_METHOD_GET]) {
                    
                    
                    
                }
                
                // PUT - Upload changes to entry
                
                if ([method isEqualToString:HTTP_METHOD_PUT]) {
                    
                    
                    
                }
                
                // DELETE - Delete entry
                if ([method isEqualToString:HTTP_METHOD_DELETE]) {
                    
                    
                    
                }
                
            }
            
            // only /blog/#/photo
            if ([pathComponents[2] isEqualToString:@"photo"] &&
                pathComponents[2] == pathComponents.lastObject) {
                
                // GET - return the Photo file
                if ([method isEqualToString:HTTP_METHOD_GET]) {
                    
                    
                    
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


@end
