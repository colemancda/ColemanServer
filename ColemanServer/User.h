//
//  User.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class Token;

@interface User : NSManagedObject
{
    NSMutableArray *_tokens;
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSNumber * permissions;

@property (readonly) NSArray *tokens;

-(Token *)createToken;

@end
