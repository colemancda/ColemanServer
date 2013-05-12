//
//  UserStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/9/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User;

@interface UserStore : NSObject
{
    NSMutableArray *_users;
    NSManagedObjectContext *_context;
    NSManagedObjectModel *_model;
    
    NSSortDescriptor *_sortDescriptor;
}

+ (UserStore *)sharedStore;

#pragma mark - Properties

@property NSTimeInterval tokenDuration;

@property (readonly) User *admin;

@property (readonly) NSString *archivePath;

@property (readonly) NSArray *allUsers;

#pragma mark

-(void)loadAllUsers;

-(BOOL)save;

-(User *)createUser;

-(void)removeUser:(User *)user;

@end
