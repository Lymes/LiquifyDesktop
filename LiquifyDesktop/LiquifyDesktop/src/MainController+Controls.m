//
//  MainController+Controls.m
//  LiquifyDesktop
//
//  Created by Marco Oliva on 24/07/15.
//
//

#import "MainController+Controls.h"
#import <ServiceManagement/ServiceManagement.h>
#import "Scene.h"





@implementation MainController (Controls)


- (void)setupControls
{
    NSDictionary *appDefaults = @{
        kGenerateRandomWaves : @(YES),
        kFollowMousePointer : @(YES),
        kShowDockIcon : @(YES),
        kPlayBackgroundMusic : @(NO),
    };

    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [self appStarted];

    self.scene.followMousePointer = [[NSUserDefaults standardUserDefaults] boolForKey:kFollowMousePointer];
    NSURL *musicUrl = [[NSBundle mainBundle] URLForResource:@"serenade" withExtension:@"mp3"];

    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:nil];
    [audioPlayer prepareToPlay];
    audioPlayer.numberOfLoops = -1;
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kPlayBackgroundMusic] )
    {
        [audioPlayer play];
    }

    BOOL showDockIcon = [[NSUserDefaults standardUserDefaults] boolForKey:kShowDockIcon];
    [NSApp setActivationPolicy:showDockIcon ? NSApplicationActivationPolicyRegular:NSApplicationActivationPolicyAccessory];


    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kGenerateRandomWaves
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kPlayBackgroundMusic
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kShowDockIcon
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kFollowMousePointer
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kRunAtStartup
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];

}


- (void)releaseControls
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kGenerateRandomWaves];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kPlayBackgroundMusic];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kShowDockIcon];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kFollowMousePointer];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kRunAtStartup];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL value = [change[ @"new" ] boolValue];

    if ( [keyPath isEqualToString:kGenerateRandomWaves] )
    {
        self.scene.generateRandomDrops = value;
    }
    else if ( [keyPath isEqualToString:kFollowMousePointer] )
    {
        self.scene.followMousePointer = value;
    }
    else if ( [keyPath isEqualToString:kPlayBackgroundMusic] )
    {
        if ( value )
        {
            [audioPlayer play];
        }
        else
        {
            [audioPlayer stop];
        }
    }
    else if ( [keyPath isEqualToString:kShowDockIcon] )
    {
        [NSApp setActivationPolicy:value ? NSApplicationActivationPolicyRegular:NSApplicationActivationPolicyAccessory];
    }
    else if ( [keyPath isEqualToString:kRunAtStartup] )
    {
        /*
           if ( value )

           {   // Turn on launch at login
            if ( !SMLoginItemSetEnabled((__bridge CFStringRef)helperAppBundleIdentifier, YES ))
            {
                NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Couldn't add Helper App to launch at login item list."];
                [alert runModal];
            }

           }
           else
           {   // Turn off launch at login
            if ( !SMLoginItemSetEnabled((__bridge CFStringRef)helperAppBundleIdentifier, NO ))
            {
                NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Couldn't remove Helper App from launch at login item list."];
                [alert runModal];
            }

           }
         */
    }
}


- (void)appStarted
{
// Check if main app was launched at login (by helper app)
    BOOL startedAtLogin = NO;

// Check if helper app is running
// If it is, main app was launched by helper app
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];

    for ( NSRunningApplication *app in apps )
    {
        if ( [app.bundleIdentifier isEqualToString:helperAppBundleIdentifier] )
        {
            startedAtLogin = YES;
        }
    }

    if ( startedAtLogin )
    {
        // Yes, main app was launched at login
        // Terminate helper app
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:terminateNotification
                                                                       object:[[NSBundle mainBundle] bundleIdentifier]];

//        // Show Info
//        NSAlert *alert = [NSAlert alertWithMessageText:@"App was launched at login." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
//        [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}


@end
