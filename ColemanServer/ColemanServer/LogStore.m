//
//  LogStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "LogStore.h"
#import "Log.h"

@implementation LogStore

+ (LogStore *)sharedStore
{
    static LogStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // initialize variable
        _logEntries = [[NSMutableArray alloc] init];
        
        // set the default date format
        self.dateStyle = NSDateFormatterMediumStyle;
        self.timeStyle = NSDateFormatterLongStyle;
        
    }
    return self;
}

#pragma mark - Properties

-(NSString *)log
{
    // return an assembled string
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = self.dateStyle;
    dateFormatter.timeStyle = self.timeStyle;
    
    NSMutableString *string = [[NSMutableString alloc] init];
    
    // build string
    for (Log *log in _logEntries) {
        
        NSString *line = [NSString stringWithFormat:@"(%@) %@\n", [dateFormatter stringFromDate:log.date], log.string];
        
        [string appendString:line];
    }
    
    return (NSString *)string.copy;
}

#pragma mark

-(void)addEntry:(NSString *)string
{
    // KVO pre change
    [self willChangeValueForKey:@"log"];
    
    // create the log
    Log *log = [[Log alloc] initWithString:string];
    
    // xcode log
    NSLog(@"%@", string);
    
    // add to array
    [_logEntries addObject:log];
    
    // KVO Post change
    [self didChangeValueForKey:@"log"];
}

-(void)addError:(NSString *)string
{
    // KVO pre change
    [self willChangeValueForKey:@"log"];
    
    // error string
    NSString *errorString = [NSString stringWithFormat:@"Error: %@", string];
    
    // create the log
    Log *log = [[Log alloc] initWithString:errorString];
    
    // xcode log
    NSLog(@"%@", errorString);
    
    // add to array
    [_logEntries addObject:log];
    
    // KVO Post change
    [self didChangeValueForKey:@"log"];
}

-(void)addTerminalError:(NSError *)error
                 reason:(NSString *)reason
{
    // KVO pre change
    [self willChangeValueForKey:@"log"];
    
    // error string
    NSString *errorString = [NSString stringWithFormat:@"Fatal Error: %@", error.localizedDescription];
    
    // create the log
    Log *log = [[Log alloc] initWithString:errorString];
    
    // add to array
    [_logEntries addObject:log];
    
    // KVO Post change
    [self didChangeValueForKey:@"log"];
    
    // save log
    [self saveToURL:[NSURL URLWithString:self.defaultArchivePath]];
    
    // present to user
    [NSApp presentError:error];
    
    // create exception
    [NSException raise:reason
                format:@"%@", error.localizedDescription];
}

#pragma mark

-(NSString *)defaultArchivePath
{
    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [documentsPaths objectAtIndex:0];
    
    NSString *folderName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    NSString *folderPath = [documentsPath stringByAppendingPathComponent:folderName];
    
    NSString *logsFolderPath = [folderPath stringByAppendingPathComponent:@"logs"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:logsFolderPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:logsFolderPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    // get a string for the current date
    
    NSString *fileName = [NSString stringWithFormat:@"log %@.txt", [NSDate date]];
        
    NSString *filePath = [logsFolderPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

-(BOOL)saveToURL:(NSURL *)url
{
    NSError *error;
    
    BOOL success = [self.log writeToURL:url
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&error];
    if (!success) {
        NSLog(@"Could not save log to %@", url.absoluteString);
    }
    else {
        NSLog(@"Successfully saved log to %@", url.absoluteString);
    }
    
    return success;
}

@end
