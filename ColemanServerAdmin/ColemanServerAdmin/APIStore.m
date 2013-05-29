//
//  APIStore.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "APIStore.h"
#import "AppDelegate.h"
#import "NSURLResponse+HTTPCode.h"

static NSString *BlogEntryEntityName = @"BlogEntry";

static NSString *notAuthorizedErrorDescription = @"You are not logged in";

static NSString *notAuthorizedErrorSuggestion = @"Please log in";

@implementation APIStore (BlogEntry)

-(NSManagedObject *)createNewBlogEntryAtIndex:(NSUInteger)index
                                         date:(NSDate *)dateCreated
{
    // save the blog entry in the core data cache...
        
    NSManagedObject *blogEntry = [NSEntityDescription insertNewObjectForEntityForName:BlogEntryEntityName
                                                               inManagedObjectContext:_context];
    
    NSString *indexKey = [NSString stringWithFormat:@"%ld", (unsigned long)index];
    
    [_blogEntriesCache setObject:blogEntry
                          forKey:indexKey];
    
    // initalized values
    [blogEntry setValue:@"" forKey:@"title"];
    [blogEntry setValue:@"" forKey:@"content"];
    [blogEntry setValue:dateCreated forKey:@"date"];
    
    return blogEntry;
}

@end

@implementation APIStore

+ (APIStore *)sharedStore
{
    static APIStore *sharedStore = nil;
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
        
        NSLog(@"Initializing API Store...");
        
        // initialize the queue
        _connectionQueue = [[NSOperationQueue alloc] init];
        
        // blog entries core data
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        _blogEntriesCache = [[NSMutableDictionary alloc] init];
        
        
    }
    return self;
}

#pragma mark - Login

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(completionBlock)completionBlock
{
    if (!username || !password || !self.baseURL) {
        return;
    }
    
    // put togeather the url
    NSString *relativeURLString = @"login";
    relativeURLString = [relativeURLString stringByAppendingPathComponent:username];
    relativeURLString = [relativeURLString stringByAppendingPathComponent:password];
    NSString *urlString = [self.baseURL stringByAppendingPathComponent:relativeURLString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"Fetching Login Token...");
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // create error to show user when we dont wanna show details
        NSString *otherErrorDescription = NSLocalizedString(@"Unable to login",
                                                       @"Unable to login");
        
        NSString *otherErrorSuggestion = NSLocalizedString(@"Try again later",
                                                      @"Try again later");
        
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: otherErrorDescription,
                                             NSLocalizedRecoverySuggestionErrorKey : otherErrorSuggestion};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4000
                                              userInfo:otherErrorUserInfo];
       
        // an error occurred
        if (error) {
            
            // 401 http error code
            if (error.code == NSURLErrorUserCancelledAuthentication) {
                
                NSString *errorDescription = NSLocalizedString(@"Your password or username is incorrect",
                                                               @"Your password or username is incorrect");
                
                NSString *errorSuggestion = NSLocalizedString(@"Type in your username and password again",
                                                              @"Type in your username and password again");
                
                NSError *wrongCredentials = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                                code:401
                                                            userInfo:
                                             @{NSLocalizedDescriptionKey: errorDescription, NSLocalizedRecoverySuggestionErrorKey : errorSuggestion}];
                if (completionBlock) {
                    completionBlock(wrongCredentials);
                }
                
                return;
                
            }
            
            // no internet or the server is offline
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // check for HTTP Status codes
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
        if (httpResponse.statusCode == 500) {
            
            NSError *serverError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                       code:httpResponse.statusCode
                                                   userInfo:otherErrorUserInfo];
            
            if (completionBlock) {
                completionBlock(serverError);
            }
            
            return;
            
        }
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        // jsonObject is nil, or not a dictionary
        if (![jsonObject isKindOfClass:[NSDictionary class]] || !jsonObject) {
            
            // json data returned from server is garbage
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        NSString *token = [jsonObject objectForKey:@"token"];
        
        // json object is not as expected
        if (!token) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully got token
        
        _token = token;
        
        NSLog(@"Successfully got authentication token");
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}

#pragma mark - Public API

-(void)fetchNumberOfEntriesWithCompletion:(completionBlock)completionBlock
{
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // create NSError for errors that we dont wanna show the user
        
        NSString *errorDescription = NSLocalizedString(@"Could not fetch the number of blog entries",
                                                       @"Could not fetch the number of blog entries");
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4001
                                              userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        
        if (error) {
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
            
        }
        
        // get the HTTP Status Code
        NSInteger httpCode = response.httpCode.integerValue;
        
        // wrong error code returned
        if (httpCode != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
            
        }
        
        // get json dictionary
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
        
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // get the value
        NSNumber *numberOfEntries = [jsonObject valueForKey:@"entries"];
        
        if (!numberOfEntries || ![numberOfEntries isKindOfClass:[NSNumber class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
            
        }
        
        // success!
        
        _numberOfEntries = numberOfEntries;
        
        NSLog(@"Successfully fetched the number of entries");
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
    
}

-(void)fetchEntry:(NSUInteger)indexOfEntry
       completion:(completionBlock)completionBlock
{
    // put togeather URL
    
    NSString *urlString = self.baseURL;
    
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    
    NSString *indexString = [NSString stringWithFormat:@"%ld", (unsigned long)indexOfEntry];
    
    urlString = [urlString stringByAppendingPathComponent:indexString];
    
    NSLog(@"Fetching Blog entry %ld", (unsigned long)indexOfEntry);
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // create other error
        
        NSString *otherErrorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not download entry %d", @"Could not download entry %d"), indexOfEntry];
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain] code:4003 userInfo:@{NSLocalizedDescriptionKey : otherErrorDescription}];
        
        // check for HTTP code error
        
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // get the json dictionary
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
        if (![jsonObject isKindOfClass:[NSDictionary class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        NSString *title = [jsonObject objectForKey:@"title"];
        
        NSString *content = [jsonObject objectForKey:@"content"];
        
        NSString *dateString = [jsonObject objectForKey:@"date"];
        
        if (!title || !content || !dateString) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
            
        }
        
        // successfully got blog entry...
        
        // get the date created
        NSDate *date = [NSDate dateWithString:dateString];
        
        NSManagedObject *blogEntry = [self createNewBlogEntryAtIndex:indexOfEntry
                                                                date:date];
        
        [blogEntry setValue:title
                     forKey:@"title"];
        [blogEntry setValue:content
                     forKey:@"content"];
        [blogEntry setValue:date
                     forKey:@"date"];
        
        NSLog(@"Successfully fetched blog entry %ld", indexOfEntry);
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}


#pragma mark - Authorized API Functions

-(void)createEntryWithCompletion:(completionBlock)completionBlock
{
    // you must already have a token do do this, and Admin user account
    
    // create the 401 error
    NSError *notAuthorizedError = [NSError errorWithDomain:[AppDelegate errorDomain] code:401 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(notAuthorizedErrorDescription, notAuthorizedErrorDescription), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(notAuthorizedErrorSuggestion, notAuthorizedErrorSuggestion)}];
    
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // create other error
    NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to create new blog entry", @"Unable to create new blog entry")};
    
    NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                              code:4002
                                          userInfo:otherErrorUserInfo];
    
    // put togeather the URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    urlString = [urlString stringByAppendingPathComponent:self.token];
    
    // make the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    request.HTTPMethod = @"POST";
    
    NSLog(@"Requesting new blog entry...");
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            // 401 error
            if (error.code == NSURLErrorUserCancelledAuthentication) {
                
                if (completionBlock) {
                    completionBlock(notAuthorizedError);
                }
                
                return;
                
            }
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // check for http response error
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // get JSON object from data
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        NSNumber *index = [jsonObject objectForKey:@"index"];
        
        if (!index) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // succesfully created new entry...
        
        // add to cache
        [self fetchEntry:index.unsignedIntegerValue completion:^(NSError *error) {
            
            if (error) {
                if (completionBlock) {
                    completionBlock(error);
                }
            }
            
            else {
                
                NSLog(@"Successfully created new blog entry %ld", index.unsignedIntegerValue);
                
                if (completionBlock) {
                    completionBlock(nil);
                }
                
                return;
                
            }
            
        }];

    }];
}

-(void)editEntry:(NSUInteger)entryIndex
         changes:(NSDictionary *)changes
      completion:(completionBlock)completionBlock
{
    if (!changes) {
        [NSException raise:@"Invalid Argument"
                    format:@"You need to specify a non-nil NSDictionary for the changes"];
    }
    
    // you must already have a token do do this, and Admin user account
    
    // create the 401 error
    NSError *notAuthorizedError = [NSError errorWithDomain:[AppDelegate errorDomain] code:401 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(notAuthorizedErrorDescription, notAuthorizedErrorDescription), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(notAuthorizedErrorSuggestion, notAuthorizedErrorSuggestion)}];
    
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // create other error
    NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to edit blog entry", @"Unable to edit blog entry")};
    
    NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                              code:4003
                                          userInfo:otherErrorUserInfo];
    
    // put togeather the URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", (unsigned long)entryIndex];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:self.token];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"PUT";

    // convert changes dictionary to JSON data
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:changes
                                                       options:0
                                                         error:nil];
    
    if (!jsonData) {
        
        NSLog(@"The changes dicitonary was not a valid JSON object");
        
        if (completionBlock) {
            completionBlock(otherError);
        }
        
        return;
        
    }
    
    // attach the data to the HTTP body
    request.HTTPBody = jsonData;
    
    NSLog(@"Sending changes request...");
    
    // send the reuqest to the server
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            // 401 error
            if (error.code == NSURLErrorUserCancelledAuthentication) {
                
                if (completionBlock) {
                    completionBlock(notAuthorizedError);
                }
                
                return;
                
            }
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // check for error HTTP status code
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
            
        }
        
        // changes successfully accepted
        
        // update cache
        NSManagedObject *blogEntry = [self.blogEntriesCache objectForKey:indexString];
        [blogEntry setValuesForKeysWithDictionary:changes];
        
        NSLog(@"Successfully changed entry %ld", entryIndex);
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}


@end
