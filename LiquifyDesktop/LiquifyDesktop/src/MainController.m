//
//  MainController.m
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "MainController.h"
#import "MainController+Controls.h"
#import "MyOpenGLView.h"
#import "Scene.h"
#import "Texture.h"


static NSURL *currentURL = nil;


#define DESKTOP_NOTIFICATION_NAME @"com.apple.desktop"
#define BACKGROUND_CHANGED        @"BackgroundChanged"
#define REVIEW_URL                @"macappstore://itunes.apple.com/app/id521153400?mt=12"



@implementation MainController

@synthesize scene = _scene;


- (void)awakeFromNib
{
    NSImage *icon = [NSImage imageNamed:@"waterdrop"];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setToolTip:@"LiquifyDesktop"];
    [statusItem setImage:icon];
    [statusItem setHighlightMode:YES];

    // Allocate the scene object
    _scene = [[Scene alloc] init];

    NSRect mainDisplayRect, viewRect;

    // Create a screen-sized window on the display you want to take over
    // Note, mainDisplayRect has a non-zero origin if the key window is on a secondary display
    mainDisplayRect = [[NSScreen mainScreen] frame];
    fullScreenWindow = [[NSWindow alloc] initWithContentRect:mainDisplayRect styleMask:NSBorderlessWindowMask
                                                     backing:NSBackingStoreBuffered defer:YES];

    [fullScreenWindow setLevel:kCGDesktopWindowLevel];
    [fullScreenWindow setIgnoresMouseEvents:YES];
    [fullScreenWindow setHidesOnDeactivate:NO];
    [fullScreenWindow setCanHide:NO];
    [fullScreenWindow setHasShadow:NO];
    [fullScreenWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [fullScreenWindow setAlphaValue:0];
    fullScreenWindow.delegate = self;

    viewRect = NSMakeRect( 0.0, 0.0, mainDisplayRect.size.width, mainDisplayRect.size.height );
    fullScreenView = [[MyOpenGLView alloc] initWithFrame:viewRect shareContext:nil];
    [fullScreenWindow setContentView:fullScreenView];
    fullScreenView.wantsLayer = NO;

    [_scene setupGL];
    [_scene setViewportRect:mainDisplayRect];

    [fullScreenView setMainController:self];

    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSMouseMovedMask | NSLeftMouseDraggedMask) handler:^( NSEvent *mouseEvent ) {
        [self->_scene setMouseLocation:[NSEvent mouseLocation]];
    }];

    [self setupControls];
 
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(registerCheckDesktopImage) name:NSWorkspaceActiveSpaceDidChangeNotification object:nil];
    
    [fullScreenView startAnimation];
    [fullScreenWindow orderFront:self];
    
    [self performSelector:@selector(showWindow) withObject:self afterDelay:1.0];
}


- (void)showWindow
{
    [fullScreenWindow setAlphaValue:1];
}


- (void)registerCheckDesktopImage
{
    SEL checkDesktopImageSelector = @selector(checkDesktopImage);

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:checkDesktopImageSelector object:self];
    [self performSelector:checkDesktopImageSelector withObject:self afterDelay:0];
}


- (void)checkDesktopImage
{
    NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[NSScreen mainScreen]];

    if ( ![[currentURL absoluteString] isEqualToString:[imageURL absoluteString]] )
    {
        currentURL = imageURL;

        [fullScreenWindow setAlphaValue:0];
        [fullScreenView stopAnimation];

        // Callback is fired, reload backgound and show program window
        [_scene reloadWallpaper];

        [fullScreenView startAnimation];

        // Flush buffer with old texture
        [fullScreenView drawView];

        [fullScreenWindow setAlphaValue:1];
    }
}


- (void)startAnimation
{
    [fullScreenView startAnimation];
}


- (void)stopAnimation
{
    [fullScreenView stopAnimation];
}


- (IBAction)showPreferences:(id)sender
{
    [prefWindow setCanHide:NO];
    [prefWindow setLevel:kCGMaximumWindowLevelKey];
    [prefWindow makeKeyAndOrderFront:sender];
}


- (IBAction)leaveFeedback:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:REVIEW_URL]];
}


- (void)windowDidChangeOcclusionState:(NSNotification *)notification
{
    if ( fullScreenWindow.occlusionState & NSWindowOcclusionStateVisible )
    {
        fullScreenView.isOccluded = NO;
    }
    else
    {
        fullScreenView.isOccluded = YES;
    }
}


@end
