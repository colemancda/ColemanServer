//
//  MainViewController.h
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ServerStore;

@interface MainViewController : NSViewController
{
    NSTimer *_refreshStatsTimer;
    
    NSTimer *_refreshUptimeTimer;
}

@property (strong) IBOutlet NSButton *startStopButton;

@property (strong) IBOutlet NSTextView *logTextView;

@property (strong) IBOutlet NSTextField *portField;

@property (strong) IBOutlet NSTextField *numberOfConnectionsLabel;

@property (strong) IBOutlet NSTextField *uptimeLabel;

-(void)updateUI;

-(void)updateServerUptimeUI;

- (IBAction)startStopServer:(id)sender;

@property (readonly) ServerStore *serverStore;

@end
