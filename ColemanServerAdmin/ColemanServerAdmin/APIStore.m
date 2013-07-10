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

NSString *const BlogEntryImageFetchedNotification = @"BlogEntryImageFetched";

NSString *const BlogEntryFetchedNotification = @"BlogEntryFetched";

NSString *const BlogEntryEditedNotification = @"BlogEntryEdited";

NSString *const NumberOfEntriesKeyPath = @"self.numberOfEntries";

static NSString *BlogEntryEntityName = @"BlogEntry";

static NSString *notAuthorizedErrorDescription = @"You are not logged in";

static NSString *notAuthorizedErrorSuggestion = @"Please log in";

static NSError *notAuthorizedError;

@implementation APIStore (CommonErrors)

-(void)initializeCommonErrors;
{
    if (!notAuthorizedError) {
        
        // create the 401 error
        notAuthorizedError = [NSError errorWithDomain:[AppDelegate errorDomain] code:401 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(notAuthorizedErrorDescription, notAuthorizedErrorDescription), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(notAuthorizedErrorSuggestion, notAuthorizedErrorSuggestion)}];
    }
}

@end

// will always give you an object. Will create a new instance if one is not found in cache
@implementation APIStore (ForceGetManagedObject)

-(NSManagedObject *)blogEntryForIndex:(NSUInteger)index
{
    // check if this entry has already been downloaded
    NSString *indexKey = [NSString stringWithFormat:@"%ld", index];
    NSManagedObject *blogEntry = [_blogEntriesCache objectForKey:indexKey];
    
    // create new one if one is not found
    if (!blogEntry) {
        
        blogEntry = [NSEntityDescription insertNewObjectForEntityForName:BlogEntryEntityName
                                                  inManagedObjectContext:_context];
        
        [_blogEntriesCache setObject:blogEntry
                              forKey:indexKey];
    }
    
    return blogEntry;
}

-(NSManagedObject *)userForUsername:(NSString *)username
{
    // get user...
    NSFetchRequest *fetchRequest = [_model fetchRequestFromTemplateWithName:@"FetchUserForUsername"
                                                      substitutionVariables:@{@"USERNAME": username}];
    
    NSError *fetchError;
    
    NSArray *results = [_context executeFetchRequest:fetchRequest
                                               error:&fetchError];
    
    if (fetchError) {
        
        [NSException raise:@"Core Data Fetch Request Error"
                    format:@"%@", fetchError.localizedDescription];
        
    }
    
    if (results.count > 1) {
        NSLog(@"There are %ld users in cache with '%@' username!", results.count, username);
    }
    
    // get user object...
    
    // if no users with that username are in cache, then create a new user
    NSManagedObject *user;
    if (!results.count) {
        
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                             inManagedObjectContext:_context];
    }
    
    else {
        
        user = results[0];
    }
    
    return user;
}

-(NSManagedObject *)commentAtIndex:(NSUInteger)commentIndex
                          forEntry:(NSUInteger)entryIndex
{
    // get blog entry
    NSManagedObject *blogEntry = [self blogEntryForIndex:entryIndex];
    
    // fetch comment...
    NSFetchRequest *fetchRequest = [_model fetchRequestFromTemplateWithName:@"FetchAllCommentsForBlogEntry"
                                                      substitutionVariables:@{@"INDEX": [NSNumber numberWithInteger:entryIndex]}];
    
    NSError *fetchError;
    
    NSArray *results = [_context executeFetchRequest:fetchRequest
                                               error:&fetchError];
    
    if (fetchError) {
        
        [NSException raise:@"Core Data Fetch Request Error"
                    format:@"%@", fetchError.localizedDescription];
        
    }
    
    for (NSManagedObject *comment in results) {
        
        NSNumber *index = [comment valueForKey:@"index"];
        
        if (index.integerValue == commentIndex) {
            
            return comment;
        }
        
    }
    
    // if none was found, then create new one
    NSManagedObject *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment"
                                                             inManagedObjectContext:_context];
    
    // set blogEntry relationship
    [comment setValue:blogEntry
               forKey:@"blogEntry"];
    
    // set index
    NSNumber *index = [NSNumber numberWithInteger:commentIndex];
    [comment setValue:index
               forKey:@"index"];
    
    return comment;
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
        
        // initliaze the common error
        [self initializeCommonErrors];
        
        // blog entries core data
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        _context.undoManager = nil;
        
        _blogEntriesCache = [[NSMutableDictionary alloc] init];
        _numberOfCommentsCache = [[NSMutableDictionary alloc] init];
        
        
    }
    return self;
}

-(void)reset
{
    // reset values
    [_context reset];
    
    _blogEntriesCache = [[NSMutableDictionary alloc] init];
    _numberOfCommentsCache = [[NSMutableDictionary alloc] init];
    
    [self willChangeValueForKey:@"numberOfEntries"];
    _numberOfEntries = nil;
    [self didChangeValueForKey:@"numberOfEntries"];
    
    self.baseURL = nil;
    self.token = nil;
    
    NSLog(@"Resetted API Store");
}

#pragma mark - Login

-(void)loginWithPassword:(NSString *)password
              completion:(completionBlock)completionBlock
{
    // put togeather the url
    NSString *relativeURLString = @"login";
    NSString *urlString = [self.baseURL stringByAppendingPathComponent:relativeURLString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // make the JSON credentials
    NSDictionary *credentials = @{@"username": self.username, @"password" : password};
    
    NSData *credentialsJSONData = [NSJSONSerialization dataWithJSONObject:credentials
                                                                  options:0
                                                                    error:nil];
    
    NSString *credentialsJSONString = [[NSString alloc] initWithData:credentialsJSONData
                                                            encoding:NSUTF8StringEncoding];
    
    // put togeather the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization": credentialsJSONString}];
    
    NSLog(@"Fetching Login Token...");
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
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
        
        NSLog(@"Successfully got authentication token");
        
        self.token = token;
        
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
    
    NSLog(@"Fetching number of entries...");
    
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
        NSNumber *numberOfEntries = [jsonObject valueForKey:@"numberOfEntries"];
        
        if (!numberOfEntries || ![numberOfEntries isKindOfClass:[NSNumber class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
            
        }
        
        // success!
        
        [self willChangeValueForKey:@"numberOfEntries"];
        _numberOfEntries = numberOfEntries;
        
        NSLog(@"Successfully fetched the number of entries");
        
        [self didChangeValueForKey:@"numberOfEntries"];
        
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
    
    NSLog(@"Fetching Blog entry %ld...", (unsigned long)indexOfEntry);
    
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
        
        // save the blog entry in the core data cache...
        
        NSManagedObject *blogEntry = [self blogEntryForIndex:indexOfEntry];
        
        [blogEntry setValue:title
                     forKey:@"title"];
        [blogEntry setValue:content
                     forKey:@"content"];
        [blogEntry setValue:date
                     forKey:@"date"];
        
        NSLog(@"Successfully fetched blog entry %@", indexString);
        
        // send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:BlogEntryFetchedNotification
                                                            object:blogEntry
                                                          userInfo:@{@"indexKey" : indexString}];
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}

-(void)fetchImageForEntry:(NSUInteger)indexOfEntry
               completion:(completionBlock)completionBlock
{    
    // put togeather URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", (unsigned long)indexOfEntry];
    urlString = [urlString  stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"photo"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"Fetching image for blog entry %ld...", indexOfEntry);
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // get blog entry
        NSManagedObject *blogEntry = [self blogEntryForIndex:indexOfEntry];
        
        if (response.httpCode.integerValue != 200) {
            
            NSLog(@"Blog entry %@ has no image", indexString);
            
            [blogEntry setValue:nil
                         forKey:@"image"];
            
            if (completionBlock) {
                completionBlock(nil);
                
                return;
            }
        }
        
        // image data
        [blogEntry setValue:data
                     forKey:@"image"];
        
        NSLog(@"Successfully fetched image for blog entry %@", indexString);
        
        // send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:BlogEntryImageFetchedNotification
                                                            object:blogEntry
                                                          userInfo:@{@"indexKey" : indexString}];
                
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}

-(void)fetchNumberOfCommentsForEntry:(NSUInteger)entryIndex
                      withCompletion:(completionBlock)completionBlock
{
    // index key
    NSString *indexString = [NSString stringWithFormat:@"%ld", entryIndex];
    
    // put togeather URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"comment"];
    
    // make request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    NSLog(@"Fetching number of comments for entry %@...", indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // create other error
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to fetch number of comments for blog entry", @"Unable to fetch number of comments for blog entry")};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4000
                                              userInfo:otherErrorUserInfo];
        
        // check for http status errors
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments error:nil];
        // check for errors
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully got number of comments
        
        NSNumber *numberOfComments = [jsonObject objectForKey:@"numberOfComments"];
        
        if (!numberOfComments) {
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully got number of comments for entry from server...
        
        // add to cache under blog entry index key
        [_numberOfCommentsCache setObject:numberOfComments
                                   forKey:indexString];
        
        NSLog(@"Successfully fetched number of comments for blog entry %@", indexString);
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
    }];
}

-(void)fetchComment:(NSUInteger)commentIndex
           forEntry:(NSUInteger)entryIndex
     withCompletion:(completionBlock)completionBlock
{
    // index key
    NSString *indexString = [NSString stringWithFormat:@"%ld", entryIndex];
    
    // put togeather URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"comment"];
    NSString *commentIndexString = [NSString stringWithFormat:@"%ld", commentIndex];
    urlString = [urlString stringByAppendingPathComponent:commentIndexString];
    
    // make request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    NSLog(@"Fetching comment %@ for entry %@...", commentIndexString, indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
       
        if (error) {
            if (completionBlock) {
                completionBlock(error);
            }
            
            return;
        }
        
        // create other error
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to fetch comment for blog entry", @"Unable to fetch comment for blog entry")};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4000
                                              userInfo:otherErrorUserInfo];
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
        
        // check for http status errors
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // check for errors
        if (!jsonObject || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // get values from JSON object
        NSString *content = [jsonObject valueForKey:@"content"];
        NSString *date = [jsonObject valueForKey:@"date"];
        NSString *username = [jsonObject valueForKey:@"user"];
        
        // check for errors
        if (!content || !date || !username) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully fetched comment from server...
        
        // get comment
        NSManagedObject *comment = [self commentAtIndex:commentIndex
                                               forEntry:entryIndex];
        
        // get user
        NSManagedObject *user = [self userForUsername:username];
        
        // set values
        [comment setValue:date
                   forKey:@"date"];
        [comment setValue:content
                   forKey:@"content"];
        [comment setValue:user
                   forKey:@"user"];
        
        // the blogEntry relationship was already set with -commentAtIndex:forEntry:
        
        NSLog(@"Successfully fetched comment %@ for entry %@", commentIndexString, indexString);
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
    
}

#pragma mark - Authorized API Functions

-(void)createEntryWithTitle:(NSString *)title
                    content:(NSString *)content
             withCompletion:(completionBlock)completionBlock
{
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
    
    // make the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = @{@"Authorization": self.token};
    
    // make JSON object
    NSDictionary *jsonObject = @{@"title" : title,
                                 @"content" : content};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:0
                                                         error:nil];
    
    request.HTTPBody = jsonData;
    
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
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:nil];
        
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
        NSInteger entryIndex = self.numberOfEntries.integerValue;
        
        // get the date created
        NSDate *date = [NSDate date];
        
        // save the blog entry in the core data cache...
        NSManagedObject *blogEntry = [self blogEntryForIndex:entryIndex];
        
        [blogEntry setValue:title
                     forKey:@"title"];
        [blogEntry setValue:content
                     forKey:@"content"];
        [blogEntry setValue:date
                     forKey:@"date"];
        
        // update numberOfEntries...
        [self willChangeValueForKey:@"numberOfEntries"];
        _numberOfEntries = [NSNumber numberWithInteger:self.numberOfEntries.integerValue + 1];
        
        NSLog(@"Successfully created new blog entry %ld", index.unsignedIntegerValue);
        
        [self didChangeValueForKey:@"numberOfEntries"];
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"PUT";
    request.allHTTPHeaderFields = @{@"Authorization": self.token};
    
    // get changes
    NSString *title = [changes objectForKey:@"title"];
    NSString *content = [changes objectForKey:@"content"];
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    if (!title && !content) {
        [NSException raise:@"Invalid changes NSDictionary"
                    format:@"Your changes dictionary should have at least one valid key"];
        
        return;
    }
    
    // add values to JSON object
    if (title) {
        [jsonObject setValue:title
                      forKey:@"title"];
    }
    
    if (content) {
        [jsonObject setValue:content
                      forKey:@"content"];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:changes
                                                       options:0
                                                         error:nil];
    
    // attach the data to the HTTP body
    request.HTTPBody = jsonData;
    
    NSLog(@"Uploading changes for entry %@...", indexString);
    
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
        
        // changes successfully uploaded
        
        // get objects to update cache
        
        
        // update cache
        NSManagedObject *blogEntry = [self blogEntryForIndex:entryIndex];
        if (title) {
            [blogEntry setValue:title
                          forKey:@"title"];
        }
        
        if (content) {
            [blogEntry setValue:content
                          forKey:@"content"];
        }
        
        NSLog(@"Successfully changed entry %ld", entryIndex);
        
        // send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:BlogEntryEditedNotification
                                                            object:blogEntry
                                                          userInfo:changes];
                
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}

-(void)removeEntry:(NSUInteger)entryIndex
        completion:(completionBlock)completionBlock
{
    // you must already have a token do do this, and Admin user account
    
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // put togeather URL
    NSString *urlString = [self.baseURL stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%lu", entryIndex];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    
    // put togeather request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"DELETE";
    request.allHTTPHeaderFields = @{@"Authorization": self.token};
    
    NSLog(@"Requesting to delete blog entry %@...", indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
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
        
        // create other error
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to delete blog entry", @"Unable to delete blog entry")};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4004
                                              userInfo:otherErrorUserInfo];
        
        // get HTTP Status code
        if (response.httpCode.integerValue != 200) {
            
            // if not authorized
            if (response.httpCode.integerValue == 401) {
                
                if (completionBlock) {
                    completionBlock(notAuthorizedError);
                }
                
                return;
            }
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully deleted blog entry on server, now we need to update the cache
        NSManagedObject *removedEntry = [_blogEntriesCache objectForKey:indexString];
        [_context deleteObject:removedEntry];
        [_blogEntriesCache removeObjectForKey:indexString];
        
        // update the keys...
        
        // change keys in order
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"integerValue"
                                                               ascending:YES];
        
        NSArray *orderedKeys = [_blogEntriesCache.allKeys sortedArrayUsingDescriptors:@[sort]];
        
        for (NSString *key in orderedKeys) {
            
            // decrease by 1 from all the keys that are equal or larger than the removed index
            if (key.integerValue >= entryIndex) {
                
                NSUInteger oldIndex = key.integerValue;
                NSUInteger newIndex = oldIndex - 1;
                
                NSString *newIndexKey = [NSString stringWithFormat:@"%ld", (unsigned long)newIndex];
                
                // get the object
                NSManagedObject *blogEntry = [_blogEntriesCache objectForKey:key];
                
                // add new key pair
                [_blogEntriesCache setObject:blogEntry
                                      forKey:newIndexKey];
                
                // if last object, remove old pair
                if (key == orderedKeys.lastObject) {
                    
                    [_blogEntriesCache removeObjectForKey:key];
                    
                }
            }
        }
        
        // update numberOfEntries
        [self willChangeValueForKey:@"numberOfEntries"];
        _numberOfEntries = [NSNumber numberWithInteger:self.numberOfEntries.integerValue - 1];
        
        NSLog(@"Successfully removed entry %@", indexString);
        
        // KVC
        [self didChangeValueForKey:@"numberOfEntries"];
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}


#pragma mark - Manipulate Images

-(void)setImageData:(NSData *)imageData
           forEntry:(NSUInteger)entryIndex
         completion:(completionBlock)completionBlock
{
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // put togeather url
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", entryIndex];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"photo"];
    
    // put togeather request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = imageData;
    request.allHTTPHeaderFields = @{@"Authorization" : self.token};
    
    NSLog(@"Uploading image data for entry %@...", indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
        
         if (error) {
             
             // 401 error - Not Authorized
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
         
         // create other error
         NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to upload image for blog entry", @"Unable to upload image for blog entry")};
         
         NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                   code:4000
                                               userInfo:otherErrorUserInfo];
         
         if (response.httpCode.integerValue != 200) {
             
             if (completionBlock) {
                 completionBlock(otherError);
             }
             
             return;
         }
         
         // successfully uploaded image data to server...
         
         // get blog entry
         NSManagedObject *blogEntry = [self blogEntryForIndex:entryIndex];
         
         // update cache
         [blogEntry setValue:imageData
                      forKey:@"image"];
         
         NSLog(@"Successfully uploaded image data for entry %@", indexString);
         
         // send notification
         [[NSNotificationCenter defaultCenter] postNotificationName:BlogEntryEditedNotification
                                                             object:blogEntry
                                                           userInfo:@{@"image": imageData}];
                  
         if (completionBlock) {
             completionBlock(nil);
         }
         
         return;
        
    }];
    
}

-(void)removeImageFromEntry:(NSUInteger)entryIndex
                 completion:(completionBlock)completionBlock
{
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // put togeather url
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", entryIndex];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"photo"];
    
    // put togeather request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"DELETE";
    request.allHTTPHeaderFields = @{@"Authorization" : self.token};
    
    
    NSLog(@"Requesting to delete image for entry %@...", indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            // 401 error - Not Authorized
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
        
        // create other error
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to delete image for blog entry", @"Unable to delete image for blog entry")};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4000
                                              userInfo:otherErrorUserInfo];
        
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
        
        // successfully deleted image on server...
        
        // get blogEntry
        NSManagedObject *blogEntry = [self blogEntryForIndex:entryIndex];
        
        // update cache
        [blogEntry setValue:nil
                     forKey:@"image"];
        
        NSLog(@"Successfully deleted image for entry %@", indexString);
        
        // send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:BlogEntryEditedNotification
                                                            object:blogEntry
                                                          userInfo:@{@"image": [NSNull null]}];
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
    }];
}

#pragma mark - Manipulate Comments

-(void)createComment:(NSString *)content
            forEntry:(NSUInteger)entryIndex
          completion:(completionBlock)completionBlock
{
    if (!self.token) {
        if (completionBlock) {
            completionBlock(notAuthorizedError);
        }
        
        return;
    }
    
    // put togeather URL
    NSString *urlString = self.baseURL;
    urlString = [urlString stringByAppendingPathComponent:@"blog"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", entryIndex];
    urlString = [urlString stringByAppendingPathComponent:indexString];
    urlString = [urlString stringByAppendingPathComponent:@"comment"];
    
    // put togeather request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = @{@"Authorization": self.token};
    
    // create JSON data to send
    NSDictionary *postJsonObject = @{@"content": content};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postJsonObject
                                                       options:0
                                                         error:nil];
    request.HTTPBody = postData;
    
    
    NSLog(@"Requesting new comment for entry %@...", indexString);
    
    [NSURLConnection sendAsynchronousRequest:request queue:_connectionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            // 401 error - Not Authorized
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
        
        // create other error
        NSDictionary *otherErrorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to create new comment for blog entry", @"Unable to create new comment for blog entry")};
        
        NSError *otherError = [NSError errorWithDomain:[AppDelegate errorDomain]
                                                  code:4000
                                              userInfo:otherErrorUserInfo];
        
        if (response.httpCode.integerValue != 200) {
            
            if (completionBlock) {
                completionBlock(otherError);
            }
            
            return;
        }
       
        // successfully created new comment on blog server
        
        // create new comment object
        NSNumber *numberOfComments = [_numberOfCommentsCache objectForKey:indexString];
        
        NSManagedObject *comment = [self commentAtIndex:numberOfComments.integerValue
                                               forEntry:entryIndex];
        
        [comment setValue:content
                   forKey:@"content"];
        [comment setValue:[NSDate date]
                   forKey:@"date"];
        
        // get user
        NSManagedObject *user = [self userForUsername:self.username];
        [comment setValue:user
                   forKey:@"user"];
        
        // update number of comments
        NSNumber *newNumberOfComments = [NSNumber numberWithInteger:numberOfComments.integerValue + 1];
        [_numberOfCommentsCache setValue:newNumberOfComments
                                  forKey:indexString];
        
        NSLog(@"Successfully created new comment for blog entry %@", indexString);
        
        if (completionBlock) {
            completionBlock(nil);
        }
        
        return;
        
    }];
}

-(void)editComment:(NSUInteger)commentIndex
          forEntry:(NSUInteger)entryIndex
           changes:(NSString *)content
        completion:(completionBlock)completionBlock
{
    
    
}

-(void)removeComment:(NSUInteger)commentIndex
            forEntry:(NSUInteger)entryIndex
          completion:(completionBlock)completionBlock
{
    
    
    
}

@end
