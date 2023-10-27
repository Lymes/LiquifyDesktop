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

#define kGenerateRandomWaves      @"generateRandomWaves"
#define kPlayBackgroundMusic      @"playBackgroundMusic"
#define kShowDockIcon             @"showDockIcon"
#define kFollowMousePointer       @"followMousePointer"
#define kRunAtStartup             @"runAtStartup"


#define helperAppBundleIdentifier @"com.lymes.LiquifyDesktopHelperApp"
#define terminateNotification     @"TERMINATEHELPER"


@class MyOpenGLView;
@class Scene;


@interface MainController : NSResponder <NSWindowDelegate> {
    
    NSWindow *fullScreenWindow;
    MyOpenGLView *fullScreenView;
    
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSWindow *prefWindow;
    
    AVAudioPlayer *audioPlayer;
}


@property (readonly, strong, nonatomic) Scene *scene;

- (IBAction)showPreferences:(id)sender;
- (IBAction)leaveFeedback:(id)sender;

- (void)startAnimation;
- (void)stopAnimation;

@end
