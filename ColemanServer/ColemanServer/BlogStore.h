//
//  BlogStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/4/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BlogEntry;

@interface BlogStore : NSObject
{
}

+ (BlogStore *)sharedStore;



@end
