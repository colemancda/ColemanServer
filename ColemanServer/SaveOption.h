//
//  SaveOption.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/12/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SaveOption : NSObject

@property NSString *name;

@property id saveTarget;

@property SEL saveSelector;

@property id backupTarget;

@property SEL backupSelector;

@end
