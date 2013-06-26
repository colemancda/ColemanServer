//
//  NSString+isNonNegativeInteger.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 6/26/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "NSString+isNonNegativeInteger.h"

static NSNumberFormatter *numberFormatter;

@implementation NSString (isNonNegativeInteger)

-(BOOL)isNonNegativeInteger
{
    if (!numberFormatter) {
        
        numberFormatter = [[NSNumberFormatter alloc] init];
    }
    
    NSNumber *number = [numberFormatter numberFromString:self];
    
    if (!number) {
        return NO;
    }
    
    // check if its below 0
    if (number.integerValue < 0) {
        return NO;
    }
    
    return YES;
}


@end
