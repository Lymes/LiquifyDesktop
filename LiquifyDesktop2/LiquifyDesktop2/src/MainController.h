//
//  MainController.h
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <AVFoundation/AVFoundation.h>

#import "MetalViewController.h"

#define kGenerateRandomWaves      @"generateRandomWaves"
#define kPlayBackgroundMusic      @"playBackgroundMusic"
#define kShowDockIcon             @"showDockIcon"
#define kFollowMousePointer       @"followMousePointer"
#define kRunAtStartup             @"runAtStartup"


#define helperAppBundleIdentifier @"com.lymes.LiquifyDesktopHelperApp"
#define terminateNotification     @"TERMINATEHELPER"


@class MyOpenGLView;


@interface MainController : NSResponder <NSWindowDelegate> {
    
    NSWindow *fullScreenWindow;
    
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSWindow *prefWindow;
    
    AVAudioPlayer *audioPlayer;
}

@property (nonatomic, readonly) MetalViewController *metalController;

- (IBAction)showPreferences:(id)sender;
- (IBAction)leaveFeedback:(id)sender;


@end
