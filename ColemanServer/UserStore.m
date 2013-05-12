//
//  UserStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/9/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "UserStore.h"
#import "User.h"
#import "LogStore.h"

@implementation UserStore

+ (UserStore *)sharedStore
{
    static UserStore *sharedStore = nil;
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
        
        NSLog(@"Initializing User Store...");
        
        // load model file
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"UserModel"
                                                  withExtension:@"momd"];
        
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // where to save SQL file
        NSURL *sqlFileURL = [NSURL fileURLWithPath:self.archivePath];
        
        NSError *error;
        
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                      configuration:nil
                                                                                                URL:sqlFileURL
                                                                                            options:nil
                                                                                              error:&error];
        if (!persistentStore) {
            
            [NSException raise:@"Open SQL file failed"
                        format:@"%@", error.localizedDescription];
            
        }
        
        // create the managed object context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = persistentStoreCoordinator;
        
        // dont need undo capability
        _context.undoManager = nil;
        
        // load all users
        [self loadAllUsers];
        
    }
    return self;
}

#pragma mark 

-(NSArray *)allUsers
{
    return (NSArray *)_users.copy;
}

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
    
    NSString *fileName = @"users.data";
    
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

-(void)loadAllUsers
{
    if (!_users) {
        
        NSLog(@"Fetching all Users...");
                
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [[_model entitiesByName] objectForKey:@"User"];
        
        fetchRequest.entity = entity;
        
        _sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"created"
                                                        ascending:YES];
        
        fetchRequest.sortDescriptors = @[_sortDescriptor];
        
        NSError *error;
        
        NSArray *result = [_context executeFetchRequest:fetchRequest
                                                  error:&error];
        
        if (!result) {
            [NSException raise:@"Could not fetch all the Users"
                        format:@"%@", error.localizedDescription];
        }
        
        _users = [[NSMutableArray alloc] initWithArray:result];
        
        [[LogStore sharedStore] addEntry:@"Successfully loaded all Users"];
        
    }
}

-(BOOL)save
{
    [[LogStore sharedStore] addEntry:@"Saving Users..."];
    
    NSError *error;
    BOOL success = [_context save:&error];
    
    if (!success) {
        
        NSString *errorEntryString = [NSString stringWithFormat:@"Could not save Users. %@", error.localizedDescription];
        
        [[LogStore sharedStore] addError:errorEntryString];
        
    }
    else {
        [[LogStore sharedStore] addEntry:@"Succesfully saved Users"];
    }
    
    return success;
}

-(User *)createUser
{
    // insert into context
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                               inManagedObjectContext:_context];
    
    // add to array (or else we wont have a pointer to it)
    [_users addObject:user];
    
    // return the user
    return user;
}

-(void)removeUser:(User *)user
{
    // delete from context
    [_context deleteObject:user];
    
    // delete from array
    [_users removeObjectIdenticalTo:user];
    
}

@end
