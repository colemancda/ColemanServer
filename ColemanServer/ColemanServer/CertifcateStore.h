//
//  CertifcateStore.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 7/16/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CertifcateStore : NSObject

+ (CertifcateStore *)sharedStore;

@property (readonly) NSString *filePath;

-(void)checkIfCertificateIsSaved;

@property (readonly) BOOL fileExists;

@end
