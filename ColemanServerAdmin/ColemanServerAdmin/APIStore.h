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

extern NSString *const BlogEntryImageFetchedNotification;

extern NSString *const BlogEntryFetchedNotification;

extern NSString *const BlogEntryEditedNotification;

extern NSString *const NumberOfEntriesKeyPath;

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

#pragma mark Blog Entries

-(void)fetchNumberOfEntriesWithCompletion:(completionBlock)completionBlock;

-(void)fetchEntry:(NSUInteger)entryIndex
       completion:(completionBlock)completionBlock;

#pragma mark Blog Entry Image

-(void)fetchImageForEntry:(NSUInteger)entryIndex
               completion:(completionBlock)completionBlock;

#pragma mark Comments

-(void)fetchNumberOfCommentsForEntry:(NSUInteger)entryIndex
                      withCompletion:(completionBlock)completionBlock;

-(void)fetchComment:(NSUInteger)commentIndex
           forEntry:(NSUInteger)entryIndex
     withCompletion:(completionBlock)completionBlock;

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

-(void)setImageData:(NSData *)imageData
           forEntry:(NSUInteger)entryIndex
         completion:(completionBlock)completionBlock;

-(void)removeImageFromEntry:(NSUInteger)entryIndex
                 completion:(completionBlock)completionBlock;

#pragma mark - Manipulate Comments

-(void)createComment:(NSString *)content
            forEntry:(NSUInteger)entryIndex
          completion:(completionBlock)completionBlock;

-(void)editComment:(NSUInteger)commentIndex
          forEntry:(NSUInteger)entryIndex
           changes:(NSString *)content
        completion:(completionBlock)completionBlock;

-(void)removeComment:(NSUInteger)commentIndex
            forEntry:(NSUInteger)entryIndex
          completion:(completionBlock)completionBlock;

@end
