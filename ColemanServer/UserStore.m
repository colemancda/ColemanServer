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
#import "AppDelegate.h"

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
        
        // set the default token duration
        self.tokenDuration = [[NSUserDefaults standardUserDefaults] floatForKey:@"tokenDuration"];
        
        // KVO token duration
        [self addObserver:self
               forKeyPath:@"self.tokenDuration"
                  options:NSKeyValueObservingOptionOld
                  context:nil];
        
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

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    if ([keyPath isEqualToString:@"self.password"] && object == self.admin) {
        
        // update user defaults
        [[NSUserDefaults standardUserDefaults] setObject:self.admin.password
                                                  forKey:@"adminPassword"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[LogStore sharedStore] addEntry:@"Admin's password changed"];
        
    }
    
    if ([keyPath isEqualToString:@"self.tokenDuration"]) {
        
        // update user defaults
        [[NSUserDefaults standardUserDefaults] setDouble:self.tokenDuration
                                                  forKey:@"tokenDuration"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *entry = [NSString stringWithFormat:@"Changed token duration to %ld", (long)self.tokenDuration];
        
        [[LogStore sharedStore] addEntry:entry];
        
    }
    
}

-(void)dealloc
{
    // remove KVO observer
    [self.admin removeObserver:self
                    forKeyPath:@"self.password"];
}

#pragma mark 

-(NSArray *)allUsers
{
    return _users;
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
        
        NSLog(@"Creating Admin user...");
        
        // create admin user
        _adminContext = [[NSManagedObjectContext alloc] init];
        _admin = [[User alloc] initWithEntity:entity
               insertIntoManagedObjectContext:_adminContext];
        
        // set the default password and username
        _admin.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"adminUsername"];
        _admin.password = [[NSUserDefaults standardUserDefaults] stringForKey:@"adminPassword"];
        
        // give admin permissions
        _admin.permissions = [NSNumber numberWithInteger:Admin];
        
        // KVO Admin's password
        [self.admin addObserver:self
                     forKeyPath:@"self.password"
                        options:NSKeyValueObservingOptionOld
                        context:nil];
        
        // add to array
        [_users insertObject:_admin
                     atIndex:0];
        
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
