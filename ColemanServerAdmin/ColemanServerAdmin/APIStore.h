//
//  APIStore.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+CompletionBlock.h"

typedef NS_ENUM(NSInteger, ServerErrorCodes) {
    
    BadRequest = 400,
    Unauthorized,
    Forbidden = 403,
    NotFound,
    ServerError = 500
    
};

// this is for communicating with the API and holding Cache
@interface APIStore : NSObject
{
    NSOperationQueue *_connectionQueue;
    
    // Blog entries core data
    NSManagedObjectContext *_context;
    NSManagedObjectModel *_model;
    
    NSMutableDictionary *_blogEntriesCache;
}

+ (APIStore *)sharedStore;

#pragma mark - Properties

@property NSString *baseURL;

@property (readonly) NSString *token;

@property (readonly) NSNumber *numberOfEntries;

@property (readonly) NSDictionary *blogEntriesCache;

#pragma mark - Login

-(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
              completion:(completionBlock)completionBlock;

#pragma mark - Public Access

-(void)fetchNumberOfEntriesWithCompletion:(completionBlock)completionBlock;

-(void)fetchEntry:(NSUInteger)indexOfEntry
       completion:(completionBlock)completionBlock;

-(void)fetchImageForEntry:(NSUInteger)indexOfEntry
               completion:(completionBlock)completionBlock;

#pragma mark - Manipulate Entries

-(void)createEntryWithTitle:(NSString *)title
                    content:(NSString *)content
             withCompletion:(completionBlock)completionBlock;

-(void)removeEntry:(NSUInteger)entryIndex
        completion:(completionBlock)completionBlock;

-(void)editEntry:(NSUInteger)entryIndex
         changes:(NSDictionary *)changes
      completion:(completionBlock)completionBlock;

#pragma mark - Manipulate Images

-(void)setImage:(NSImage *)image
       forEntry:(NSUInteger)indexOfEntry
     completion:(completionBlock)completionBlock;

-(void)removeImageFromEntry:(NSUInteger)entryIndex
                 completion:(completionBlock)completionBlock;


@end
