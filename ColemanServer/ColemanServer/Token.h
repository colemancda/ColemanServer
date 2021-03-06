//
//  Token.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/27/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Token : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * stringValue;
@property (nonatomic, retain) User *user;

@end
