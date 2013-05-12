//
//  ToolBarController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToolBarController : NSObject

@property (strong) IBOutlet NSToolbar *toolbar;

- (IBAction)server:(id)sender;

- (IBAction)save:(id)sender;

- (IBAction)users:(id)sender;



@end
