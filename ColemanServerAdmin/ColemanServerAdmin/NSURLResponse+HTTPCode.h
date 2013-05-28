//
//  NSURLResponse+HTTPCode.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/23/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLResponse (HTTPCode)

@property (readonly) NSNumber *httpCode;

@end
