//
//  NSString+Counter.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/5/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Counter)

+(NSString *)counterStringFromSeconds:(NSTimeInterval)counterSeconds;

@end
