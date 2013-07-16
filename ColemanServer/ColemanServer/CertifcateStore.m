//
//  CertifcateStore.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/16/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "CertifcateStore.h"
#import "LogStore.h"

@implementation CertifcateStore

+ (CertifcateStore *)sharedStore
{
    static CertifcateStore *sharedStore = nil;
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
        
        NSLog(@"Initializing Certificate Store...");
        
        [self checkIfCertificateIsSaved];
        
    }
    return self;
}

#pragma mark

-(void)checkIfCertificateIsSaved
{
    NSLog(@"Checking if certificate is saved...");
    
    [self willChangeValueForKey:@"fileExists"];
    
    _fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
    
    [self didChangeValueForKey:@"fileExists"];
    
    NSLog(@"Certificate exists: %d", self.fileExists);
}

#pragma mark

-(NSString *)filePath
{
    NSArray *appSupportDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    
    NSString *appSupportDirectoryPath = [appSupportDirectories objectAtIndex:0];
    
    NSString *folderName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    NSString *folderPath = [appSupportDirectoryPath stringByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
    
    NSString *filePath = [folderPath stringByAppendingPathComponent:@"certificate.crt"];
    
    return filePath;
}

@end
