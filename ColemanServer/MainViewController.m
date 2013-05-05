//
//  MainViewController.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/3/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "MainViewController.h"
#import "LogStore.h"
#import "ServerStore.h"
#import "NSString+Counter.h"

@interface MainViewController ()

@end

@implementation MainViewController

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

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // KVO Log text
    [[LogStore sharedStore] addObserver:self
                             forKeyPath:@"self.log"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
    // update the stats
    [self updateUI];
    
    // timer
    _refreshStatsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(updateUI)
                                                        userInfo:nil
                                                         repeats:YES];
    
    _refreshUptimeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:self
                                                         selector:@selector(updateServerUptimeUI)
                                                         userInfo:nil
                                                          repeats:YES];
}

-(void)dealloc
{
    // remove KVO observers
    [[LogStore sharedStore] removeObserver:self forKeyPath:@"self.log"];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // log string changed
    if ([keyPath isEqualToString:@"self.log"] && object == [LogStore sharedStore]) {
        
        [self updateUI];
        
    }
}

#pragma mark

-(void)updateUI
{
    // update the UI's Log
    self.logTextView.string = [LogStore sharedStore].log;
    
    // scroll to bottom of log
    [self.logTextView scrollToEndOfDocument:self];
    
    // update the number of connections
    self.numberOfConnectionsLabel.integerValue = [ServerStore sharedStore].numberOfConnections;
    
    // update whether the server is running or not
    if ([ServerStore sharedStore].isRunning) {
        
        // set button state
        self.startStopButton.state = NSOnState;
        
        // update text field
        [self.portField setEnabled:NO];
        self.portField.integerValue = [ServerStore sharedStore].port;
                
    }
    else {
        
        [self.portField setEnabled:YES];
        self.startStopButton.state = NSOffState;
        
    }
    
    // update seconds run
    [self updateServerUptimeUI];
    
}

-(void)updateServerUptimeUI
{
    if ([ServerStore sharedStore].isRunning) {
        
        NSTimeInterval secondsUptime = [ServerStore sharedStore].serverUpTime;
        
        NSString *uptimeString = [NSString counterStringFromSeconds:secondsUptime];
        
        // update uptime UI
        self.uptimeLabel.stringValue = uptimeString;
        
    }
    else {
        
        // update uptime
        NSString *uptimeString = [NSString stringWithFormat:@"Server is off"];
        
        self.uptimeLabel.stringValue = uptimeString;
    }
    
}

#pragma mark - Action Buttons

- (IBAction)startStopServer:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    // start...
    if (button.state == NSOnState) {
        
        NSInteger portNumber = self.portField.integerValue;
        
        [[ServerStore sharedStore] startServerWithPort:portNumber];
        
        // update the UI
        [self updateUI];
        
    }
    
    // stop server...
    else {
        
        [[ServerStore sharedStore] stopServer];
        
        [self.portField setEnabled:YES];
    }
    
    
}

@end
