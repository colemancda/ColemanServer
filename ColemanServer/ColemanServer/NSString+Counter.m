//
//  NSString+Counter.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/5/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "NSString+Counter.h"

@implementation NSString (Counter)

+(NSString *)counterStringFromSeconds:(NSTimeInterval)counterSeconds
{
    NSString *counterString;
    
    // values
    NSInteger minute = 60;
    NSInteger hour = minute * 60;
    // NSInteger day = hour * 24;
    
    // if less then 1 minute, then show in seconds
    if (counterSeconds < minute) {
        
        counterString = [NSString stringWithFormat:@"%.1f seconds", counterSeconds];
        
    }
    // more then a minute
    else {
        
        if (counterSeconds < hour) {
            
            NSInteger minutes = (NSInteger)(counterSeconds / minute);
            
            NSTimeInterval seconds = (counterSeconds - (minute * minutes));
            
            counterString = [NSString stringWithFormat:@"%ld minutes %.1f seconds", (long)minutes, seconds];
        }
        // more then an hour
        else {
            
            NSInteger hours = (NSInteger)(counterSeconds / hour);
            
            NSInteger minutes = (NSInteger)((counterSeconds - (hours * hour)) / minute);
            
            counterString = [NSString stringWithFormat:@"%ld hours %ld minutes", hours, minutes];
            
        }
        
    }
    
    return counterString;
}

@end
