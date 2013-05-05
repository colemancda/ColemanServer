//
//  MainViewController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController
{
    NSTimer *_refreshStatsTimer;
}

@property (strong) IBOutlet NSButton *startStopButton;

@property (strong) IBOutlet NSTextView *logTextView;

@property (strong) IBOutlet NSTextField *portField;

@property (strong) IBOutlet NSTextField *numberOfConnectionsLabel;


-(void)updateUI;

- (IBAction)startStopServer:(id)sender;

@end
