//
//  User.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/27/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EntryComment, Token;

typedef NS_ENUM(NSInteger, UserPermissionLevel) {
    
    Admin = 100,
    Viewer = 0
    
};

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * permissions;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *tokens;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(EntryComment *)value;
- (void)removeCommentsObject:(EntryComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addTokensObject:(Token *)value;
- (void)removeTokensObject:(Token *)value;
- (void)addTokens:(NSSet *)values;
- (void)removeTokens:(NSSet *)values;

@end
