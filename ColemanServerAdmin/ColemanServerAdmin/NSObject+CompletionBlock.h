//
//  NSObject+CompletionBlock.h
//  DamnFit
//
//  Created by Alsey Coleman Miller on 5/7/13.
//  Copyright (c) 2013 Hype. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completionBlock) (NSError *error);

@interface NSObject (CompletionBlock)

@end
