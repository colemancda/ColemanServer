//
//  Log.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Log : NSObject

@property (readonly) NSString *string;

@property (readonly) NSDate *date;

- (id)initWithString:(NSString *)string;


@end
