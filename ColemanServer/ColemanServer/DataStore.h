//
//  DataStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/26/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BlogEntry, User;

@interface DataStore : NSObject
{
    NSMutableArray *_blogEntries;
    NSMutableArray *_allUsers;
    
    NSManagedObjectContext *_context;
    NSManagedObjectModel *_model;
    
    NSSortDescriptor *_dateSortDescriptor;
}

+ (DataStore *)sharedStore;

#pragma mark - Store Actions

@property (readonly) NSString *archivePath;

-(BOOL)save;

#pragma mark - Blog Entries

-(void)loadAllEntries;

@property (readonly) NSArray *allEntries;

-(BlogEntry *)createEntry;

-(void)removeEntry:(BlogEntry *)blogEntry;

#pragma mark - Users

-(void)loadAllUsers;

-(void)loadAdminUser;

@property (readonly) NSArray *allUsers;

@property (readonly) User *admin;

-(User *)createUser;

-(void)removeUser:(User *)user;



@end
