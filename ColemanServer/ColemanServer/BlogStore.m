//
//  BlogStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/4/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "BlogStore.h"
#import <CoreData/CoreData.h>
#import "LogStore.h"
#import "BlogEntry.h"

@implementation BlogStore

+ (BlogStore *)sharedStore
{
    static BlogStore *sharedStore = nil;
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
        
        NSLog(@"Initializing Blog Store...");
        
        // create sort descriptor
        _sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                        ascending:YES];
        
        // get the model file
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BlogModel"
                                                  withExtension:@"momd"];
        
        // read in all the Core Data files
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSPersistentStoreCoordinator *persistanceStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // where to save SQLite file
        NSURL *persistanceURL = [NSURL fileURLWithPath:self.archivePath];
        
        NSError *error;
        
        NSPersistentStore *persistanceStore = [persistanceStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistanceURL options:nil error:&error];
        
        if (!persistanceStore) {
            
            [NSException raise:@"Opening Blog persistance failed"
                        format:@"%@", error.localizedDescription];
        }
        
        // create the context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = persistanceStoreCoordinator;
        
        // we dont support undo
        _context.undoManager = nil;
        
        // load all items
        [self loadAllItems];
        
    }
    return self;
}

#pragma mark

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
    
    NSString *fileName = @"blogEntries.data";
    
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

-(NSArray *)allEntries
{
    return (NSArray *)_blogEntries;
}

-(BOOL)save
{
    [[LogStore sharedStore] addEntry:@"Saving blog entries..."];
    
    NSError *error;
    
    BOOL success = [_context save:&error];
    
    if (!success) {
        
        NSString *errorMessage = [NSString stringWithFormat:@"Could not save blog entries. %@", error.localizedDescription];
        
        [[LogStore sharedStore] addError:errorMessage];
        
    }
    else {
        
        [[LogStore sharedStore] addEntry:@"Successfully saved blog entries"];
        
    }
    
    return success;
}

-(void)loadAllItems
{
    // will only work once
    if (!_blogEntries) {
        
        // Log
        NSLog(@"Fetching all blog entries...");
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [_model.entitiesByName objectForKey:@"BlogEntry"];
        
        request.entity = entity;
        
        request.sortDescriptors = @[_sortDescriptor];
        
        NSError *fetchError;
        
        NSArray *result = [_context executeFetchRequest:request
                                                  error:&fetchError];
        if (!result) {
            
            [NSException raise:@"Fetch failed"
                        format:@"%@", fetchError.localizedDescription];
            
        }
        
        // save
        _blogEntries = [[NSMutableArray alloc] initWithArray:result];
        
        // log
        [[LogStore sharedStore] addEntry:@"Successfully loaded all blog entries"];
        
    }
    
}

-(BlogEntry *)createEntry
{
    // create new item in context
    BlogEntry *entry = [NSEntityDescription insertNewObjectForEntityForName:@"BlogEntry" inManagedObjectContext:_context];
    
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

@end
