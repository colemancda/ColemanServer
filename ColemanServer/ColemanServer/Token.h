//
//  Token.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/10/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Token : NSObject

@property (readonly) NSString *stringValue;

@property (readonly) NSDate *created;

@end
