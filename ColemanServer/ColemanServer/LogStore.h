//
//  LogStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogStore : NSObject
{
    NSMutableArray *_logEntries;
}

+ (LogStore *)sharedStore;

@property (readonly) NSString *log;

@property NSDateFormatterStyle dateStyle;

@property NSDateFormatterStyle timeStyle;

-(void)addEntry:(NSString *)string;

-(void)addError:(NSString *)string;

-(void)addTerminalError:(NSError *)error
                 reason:(NSString *)reason;

@property (readonly) NSString *defaultArchivePath;

-(BOOL)saveToURL:(NSURL *)url;

@end
