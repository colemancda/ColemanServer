//
//  DataStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/26/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "DataStore.h"
#import "LogStore.h"
#import "User.h"
#import "BlogEntry.h"
#import "Token.h"

@implementation DataStore

+ (DataStore *)sharedStore
{
    static DataStore *sharedStore = nil;
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
        
        NSLog(@"Initializing DataStore...");
        
        // read in all Model files
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        // create persistent store coordinator
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // where to save SQL file
        NSURL *persistanceURL = [NSURL fileURLWithPath:self.archivePath];
        
        NSError *openPersistanceError;
        
        NSPersistentStore *persistanceStore = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                                configuration:nil
                                                                          URL:persistanceURL
                                                                      options:nil
                                                                        error:&openPersistanceError];
        
        // error opening file or creating it
        if (!persistanceStore) {
            
            [[LogStore sharedStore] addError:openPersistanceError.localizedDescription];
            
            [[LogStore sharedStore] saveToURL:[NSURL fileURLWithPath:[LogStore sharedStore].defaultArchivePath]];
            
            [NSApp presentError:openPersistanceError];
            
            [NSException raise:@"Opening Persistance Failed"
                        format:@"%@", openPersistanceError];
            
            
        }
        
        // create the context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = psc;
        
        // we dont support undo
        _context.undoManager = nil;
        
        // start fetching the blog entries, Users and the admin
        [self loadAllEntries];
        [self loadAllUsers];
        
    }
    
    return self;
}

#pragma mark - Archive Path

-(NSString *)archivePath
{
    NSArray *appSupportDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupportDirectoryPath = [appSupportDirectories objectAtIndex:0];
    
    NSString *folderName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    NSString *folderPath = [appSupportDirectoryPath stringByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSString *fileName = @"colemanserver.data";
    
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

#pragma mark - Loading

-(void)loadAllEntries
{
    if (!_blogEntries) {
        
        NSLog(@"Fetching all Blog Entries...");
        
        // create fetch reuqest from model and create mutable copy
        NSFetchRequest *fetchRequest = [_model fetchRequestTemplateForName:@"AllEntries"].copy;
        
        // create sort descriptor
        NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                                   ascending:YES];
        
        fetchRequest.sortDescriptors = @[dateSort];
        
        NSError *fetchError;
        
        NSArray *result = [_context executeFetchRequest:fetchRequest
                                                  error:&fetchError];
        
        // could not fetch the blog entries
        if (!result) {
            
            [[LogStore sharedStore] addError:fetchError.localizedDescription];
            
            [[LogStore sharedStore] saveToURL:[NSURL URLWithString:[LogStore sharedStore].defaultArchivePath]];
            
            [NSApp presentError:fetchError];
            
            [NSException raise:@"Could not fetch all the Blog Entries"
                        format:@"%@", fetchError.localizedDescription];
            
        }
        
        // create mutable array
        _blogEntries = [[NSMutableArray alloc] initWithArray:result];
        
        [[LogStore sharedStore] addEntry:@"Successfully loaded all Blog Entries"];
    }
    
}

-(void)loadAllUsers
{
    if (!_allUsers) {
        
        NSLog(@"Fetching all Users...");
        
        // get fetch request
        NSFetchRequest *allUsersFetchRequest = [_model fetchRequestTemplateForName:@"AllUsers"].copy;
        
        // create sort descriptor
        NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"created"
                                                                   ascending:YES];
        
        // set sorting
        allUsersFetchRequest.sortDescriptors = @[dateSort];
        
        NSError *fetchAllUsersError;
        
        NSArray *allUsersResult = [_context executeFetchRequest:allUsersFetchRequest
                                                          error:&fetchAllUsersError];
        
        // if we could not fetch the results, we terminate the app
        if (!allUsersResult) {
            
            [[LogStore sharedStore] addError:fetchAllUsersError.localizedDescription];
            
            [[LogStore sharedStore] saveToURL:[NSURL URLWithString:[LogStore sharedStore].defaultArchivePath]];
            
            [NSApp presentError:fetchAllUsersError];
            
            [NSException raise:@"Could not fetch all the Users"
                        format:@"%@", fetchAllUsersError.localizedDescription];
            
        }
        
        // create mutable array
        _allUsers = [NSMutableArray arrayWithArray:allUsersResult];
        
        // load the Admin user
        [self loadAdminUser];
        
        [[LogStore sharedStore] addEntry:@"Successfully loaded all Users"];
        
    }
}

-(void)loadAdminUser
{
    if (!_admin) {
        
        NSLog(@"Fetching Admin User...");
        
        NSFetchRequest *adminFetchRequest = [_model fetchRequestTemplateForName:@"FetchAdmin"].copy;
        
        // we dont sort the results becuase there should only be one...
        
        NSError *fetchAdminError;
        
        NSArray *adminResult = [_context executeFetchRequest:adminFetchRequest
                                                       error:&fetchAdminError];
        
        if (!adminResult) {
            
            [[LogStore sharedStore] addTerminalError:fetchAdminError
                                              reason:@"Could not fetch the admin"];
            
        }
        
        // check if the array has more than 1 admin
        if (adminResult.count > 1) {
            
            [[LogStore sharedStore] addError:[NSString stringWithFormat:@"%ld Admins exist!",
                                              (unsigned long)adminResult.count]];
            
        }        
        
        // create admin if one doesnt exist
        if (!adminResult.count) {
            
            // create admin user
            _admin = [self createUser];
            
            _admin.permissions = [NSNumber numberWithInteger:Admin];
            
            _admin.username = @"admin";
            
            _admin.password = @"admin";
            
        }
        
        else {
            
            // get the admin
            _admin = adminResult[0];
            
        }
        
        [[LogStore sharedStore] addEntry:@"Successfully loaded Admin User"];
        
    }
    
}

#pragma mark - Properties

-(NSArray *)allEntries
{
    return _blogEntries;
}

-(NSArray *)allUsers
{
    return _allUsers;
}

#pragma mark - Add / Remove

-(BlogEntry *)createEntry
{
    // create new item in context
    BlogEntry *entry = [NSEntityDescription insertNewObjectForEntityForName:@"BlogEntry"
                                                     inManagedObjectContext:_context];
    
    // add to array (or else we wont have a pointer to it)
    [_blogEntries addObject:entry];
    
    // return
    return entry;
    
}

-(void)removeEntry:(BlogEntry *)blogEntry
{
    // delete from core data context
    [_context deleteObject:blogEntry];
    
    // delete from array
    [_blogEntries removeObjectIdenticalTo:blogEntry];
    
}

-(User *)createUser
{
    // insert into context
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                               inManagedObjectContext:_context];
    
    // add to array (or else we wont have a pointer to it)
    [_allUsers addObject:user];
    
    // return the user
    return user;
}

-(void)removeUser:(User *)user
{
    // delete from context
    [_context deleteObject:user];
    
    // delete from array
    [_allUsers removeObjectIdenticalTo:user];
    
}

#pragma mark - Save

-(BOOL)save
{
    [[LogStore sharedStore] addEntry:@"Saving DataStore..."];
    
    NSError *error;
    
    BOOL success = [_context save:&error];
    
    if (!success) {
        
        NSString *errorMessage = [NSString stringWithFormat:@"Could not save DataStore. %@", error.localizedDescription];
        
        [[LogStore sharedStore] addError:errorMessage];
        
    }
    else {
        
        [[LogStore sharedStore] addEntry:@"Successfully saved DataStore"];
        
    }
    
    return success;
}

#pragma mark - Search

-(User *)userForUsername:(NSString *)username
                password:(NSString *)password
{
    // fetch from the context a user matching the username
    NSFetchRequest *fetchRequest = [_model fetchRequestFromTemplateWithName:@"FetchUserForUsername"
                                                      substitutionVariables:@{@"USERNAME": username}];
    
    NSError *fetchError;
    
    // execute search
    NSArray *result = [_context executeFetchRequest:fetchRequest
                                              error:&fetchError];
    
    if (!result) {
        
        NSString *errorDescription = [NSString stringWithFormat:@"Could not fetch request for username '%@'. %@", username, fetchError];
        
        [[LogStore sharedStore] addError:errorDescription];
        
        return nil;
    }
    
    // got results...
    
    // check if any users were found
    if (!result.count) {
        
        return nil;
    }
    
    // warn if there are multiple users with same username
    if (result.count > 1) {
        
        NSString *multipleUsersError = [NSString stringWithFormat:@"There are %ld Users with the '%@' username!", (unsigned long)result.count, username];
        
        [[LogStore sharedStore] addError:multipleUsersError];
        
    }
    
    User *user = result[0];
    
    return user;
}

-(Token *)tokenWithStringValue:(NSString *)stringValue
{
    NSFetchRequest *fetchRequest = [_model fetchRequestFromTemplateWithName:@"FetchToken"
                                                      substitutionVariables:@{@"STRINGVALUE": stringValue}];
    
    NSError *fetchError;
    
    // execute the request
    NSArray *result = [_context executeFetchRequest:fetchRequest
                                              error:&fetchError];
    
    if (!result) {
        
        NSString *fetchErrorDescription = [NSString stringWithFormat:@"Could not fetch request for token stingValue '%@'. %@", stringValue, fetchError.localizedDescription];
        
        [[LogStore sharedStore] addError:fetchErrorDescription];
        
        return nil;
    }
    
    // if no tokens were found
    if (!result.count) {
        
        return nil;
    }
    
    // warn if there are multiple tokens with the same string value
    if (result.count > 1) {
        
        NSString *multipleTokensError = [NSString stringWithFormat:@"There are %ld Tokens with '%@' stringValue!", (unsigned long)result.count, stringValue];
        
    }
    
    Token *token = result[0];
    
    return token;
    
}

#pragma mark - Advanced Actions

-(Token *)createTokenForUser:(User *)user
{
    // create new token
    Token *token = [NSEntityDescription insertNewObjectForEntityForName:@"Token"
                                                 inManagedObjectContext:_context];
    
    // add to to user
    [user addTokensObject:token];
    
    return token;
}

-(EntryComment *)createCommentForUser:(User *)user
                            blogEntry:(BlogEntry *)entry
{
    // create new comment
    EntryComment *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment"
                                                          inManagedObjectContext:_context];
    
    // add to user
    [user addCommentsObject:comment];
    
    // add to blog entry
    [entry addCommentsObject:comment];
    
    return comment;
}

@end
