//
//  AppDelegate.m
//  LiquifyDesktop
//
//  Created by Leonid Mesentsev on 25/07/15.
//
//

#import "AppDelegate.h"


@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}


- (void)applicationDidChangeOcclusionState:(NSNotification *)n
{
    if ( [NSApp occlusionState] & NSApplicationOcclusionStateVisible )
    {
        // Visible
    }
    else
    {
        // Occluded
    }
}


@end
