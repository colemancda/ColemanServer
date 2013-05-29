//
//  LoginViewController.h
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 5/17/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginViewController : NSViewController

// loading View
@property (strong) IBOutlet NSView *loadingView;

@property (strong) IBOutlet NSProgressIndicator *loadingIndicator;

@property (strong) IBOutlet NSTextField *loadingTextView;


// login form

@property (strong) IBOutlet NSBox *loginBox;

@property (strong) IBOutlet NSTextField *apiURLTextField;

@property (strong) IBOutlet NSSecureTextField *passwordField;

- (IBAction)login:(id)sender;

#pragma mark - Show / Hide Loading View

-(void)showLoadingView;

-(void)hideLoadingView;

@end
