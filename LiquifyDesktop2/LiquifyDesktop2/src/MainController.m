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
#import "Texture.h"


static NSURL *currentURL = nil;


#define DESKTOP_NOTIFICATION_NAME @"com.apple.desktop"
#define BACKGROUND_CHANGED        @"BackgroundChanged"
#define REVIEW_URL                @"macappstore://itunes.apple.com/app/id521153400?mt=12"


@interface MainController () {
    
    
}

@end


@implementation MainController


- (void)awakeFromNib
{
    int windowId = [Texture getDesktopWindowId];
    if (windowId == -1) {
        CGRequestScreenCaptureAccess();
        return;
    }
    
    NSImage *icon = [NSImage imageNamed:@"waterdrop"];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    statusItem.button.toolTip = @"LiquifyDesktop";
    statusItem.button.image = icon;
    statusItem.button.cell.highlighted = YES;

    NSRect mainDisplayRect, viewRect;

    // Create a screen-sized window on the display you want to take over
    // Note, mainDisplayRect has a non-zero origin if the key window is on a secondary display
    mainDisplayRect = [[NSScreen mainScreen] frame];
    fullScreenWindow = [[NSWindow alloc] initWithContentRect:mainDisplayRect styleMask:NSWindowStyleMaskBorderless
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
    NSView *fullScreenView = [[NSView alloc] initWithFrame:viewRect];
    [fullScreenWindow setContentView:fullScreenView];
    fullScreenView.wantsLayer = NO;

    _metalController = [MetalViewController new];
    _metalController.view = fullScreenView;
    [_metalController viewDidLoad];
    _metalController.metalView.paused = YES;

    [self setupControls];
 
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(registerCheckDesktopImage) name:NSWorkspaceActiveSpaceDidChangeNotification object:nil];
    
    [fullScreenWindow orderFront:self];
    [self performSelector:@selector(showWindow) withObject:self afterDelay:1.0];
    _metalController.metalView.paused = NO;
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
        // Callback is fired, reload backgound and show program window
        [_metalController reloadWallpaper];
        [fullScreenWindow setAlphaValue:1];
    }
}


- (void)startAnimation
{
    _metalController.metalView.paused = NO;
}


- (void)stopAnimation
{
    _metalController.metalView.paused = YES;
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
        _metalController.metalView.paused = NO;
        _metalController.followMousePointer  = [[NSUserDefaults standardUserDefaults] boolForKey:kFollowMousePointer];
        //_metalController.generateRandomDrops = [[NSUserDefaults standardUserDefaults] boolForKey:kGenerateRandomWaves];
    }
    else
    {
        _metalController.metalView.paused = YES;
        _metalController.followMousePointer  = NO;
        //_metalController.generateRandomDrops = NO;
    }
}


@end
