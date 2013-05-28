//
//  UsersViewController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/11/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "UsersViewController.h"
#import "UserStore.h"

@interface UsersViewController ()

@end

@implementation UsersViewController

- (id)init
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(UserStore *)userStore
{
    return [UserStore sharedStore];
}

@end
