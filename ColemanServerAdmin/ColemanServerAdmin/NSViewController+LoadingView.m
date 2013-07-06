//
//  NSViewController+LoadingView.m
//  ColemanServerAdmin
//
//  Created by Alsey Coleman Miller on 7/6/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "NSViewController+LoadingView.h"

static NSView *loadingView;

@implementation NSViewController (LoadingView)

-(void)showLoadingView:(BOOL)show
{
    if (show) {
        
        // get XIB
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"LoadingView"
                                              bundle:nil];
        
        NSArray *views;
        BOOL success = [nib instantiateWithOwner:nil
                                 topLevelObjects:&views];
        
        loadingView = views[1];
        
        [self.view addSubview:loadingView];
        
    }
    
    else {
        
        [loadingView removeFromSuperview];
        
        loadingView = nil;
    }
    
}

@end
