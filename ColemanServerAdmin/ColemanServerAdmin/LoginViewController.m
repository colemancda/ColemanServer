//
//  LoginViewController.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "LoginViewController.h"
#import "APIStore.h"
#import "AppDelegate.h"
#import "BlogEntriesViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

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

-(void)viewDidLoad
{
    
    
}

-(void)viewDidAppear
{
    [self hideLoadingView];
}


#pragma mark

- (IBAction)login:(id)sender {
    
    // show loading UI
    [self showLoadingView];
    
    // get string for authentication
    NSString *urlString = self.apiURLTextField.stringValue;
    
    NSString *password = self.passwordField.stringValue;
    
    // login...
    [APIStore sharedStore].baseURL = urlString;
    
    [[APIStore sharedStore] loginWithUsername:@"admin" password:password completion:^(NSError *error) {
        
        // present error
        if (error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [NSApp presentError:error];
                
                [self hideLoadingView];
                
            }];
            
            return;
        }
        
        // got token
        NSLog(@"Got token '%@'", [APIStore sharedStore].token);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            BlogEntriesViewController *entriesVC = [[BlogEntriesViewController alloc] init];
            
            [self pushViewController:entriesVC];
            
        }];
        
    }];
    
}

#pragma mark - Show / Hide Loading View

-(void)showLoadingView
{
    // show loading UI
    self.loadingView.frame = self.view.bounds;
    [self.view addSubview:self.loadingView];
    [self.loginBox setHidden:YES];
    
    [self.loadingIndicator startAnimation:nil];
}

-(void)hideLoadingView
{
    [self.loadingView removeFromSuperview];
    [self.loginBox setHidden:NO];
}



@end
