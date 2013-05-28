//
//  UsersViewController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class UserStore;

@interface UsersViewController : NSViewController

@property (readonly) UserStore *userStore;

@end
