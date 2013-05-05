//
//  BlogStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/4/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlogStore : NSObject
{
    NSMutableArray *_blogEntries;
    NSManagedObjectContext *_context;
    NSManagedObjectModel *_model;
}

+ (BlogStore *)sharedStore;

@property (readonly) NSString *archivePath;

-(BOOL)save;

-(void)loadAllItems;

@property (readonly) NSArray *allEntries;

@end
