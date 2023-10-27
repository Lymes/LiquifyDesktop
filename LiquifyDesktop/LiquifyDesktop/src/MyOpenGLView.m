//
//  MyOpenGLView.m
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import "MyOpenGLView.h"
#import "MainController.h"
#import "Scene.h"



@implementation MyOpenGLView


- (NSOpenGLContext *)openGLContext
{
    return openGLContext;
}


- (NSOpenGLPixelFormat *)pixelFormat
{
    return pixelFormat;
}


- (void)setMainController:(MainController *)theController;
{
    controller = theController;
}


- (CVReturn)getFrameForTime:(const CVTimeStamp *)outputTime
{
    if ( !_isOccluded && displayLink && CVDisplayLinkIsRunning( displayLink ))
    {
        // There is no autorelease pool when this method is called because it will be called from a background thread
        // It's important to create one or you will leak objects
        @autoreleasepool
        {
            // Update the animation
            [[controller scene] update];

            [self drawView];

//            dispatch_async(dispatch_get_main_queue(), ^() {
//                [[self openGLContext] makeCurrentContext];
//                [[controller scene] render];
//                [[self openGLContext] flushBuffer];
//            });
        }
    }
    return kCVReturnSuccess;
}


// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback( CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext )
{
    [(__bridge MyOpenGLView *)displayLinkContext getFrameForTime:outputTime];
    return kCVReturnSuccess;
}


- (void)setupDisplayLink
{
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays( &displayLink );

    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback( displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));

    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext( displayLink, cglContext, cglPixelFormat );
}


- (id)initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext *)context
{
    NSOpenGLPixelFormatAttribute attribs[] =
    {
        kCGLPFAAccelerated,
        kCGLPFANoRecovery,
        kCGLPFADoubleBuffer,
        kCGLPFAColorSize,            32,
        NSOpenGLPFAAuxDepthStencil,
        
        NSOpenGLPFASampleBuffers,    2,
        NSOpenGLPFASamples,          4,
        NSOpenGLPFADepthSize,        32,
        NSOpenGLPFAAlphaSize,        32,
        
        kCGLPFAAllowOfflineRenderers,
        1262,
        0

        
//        kCGLPFAAccelerated,
//        kCGLPFANoRecovery,
//        kCGLPFADoubleBuffer,
//        kCGLPFAColorSize,            24,
//        kCGLPFADepthSize,            16,
//        kCGLPFAAllowOfflineRenderers,
//        1262,
//        0
    };

    if ( self = [super initWithFrame:frameRect] )
    {
        pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];

        if ( !pixelFormat )
        {
            NSLog( @"No OpenGL pixel format" );
        }

        // NSOpenGLView does not handle context sharing, so we draw to a custom NSView instead
        openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];

        [[self openGLContext] makeCurrentContext];

        // Synchronize buffer swaps with vertical refresh rate
        GLint swapInt = 1;
        [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

        [self setupDisplayLink];

        // Look for changes in view size
        // Note, -reshape will not be called automatically on size changes because NSView does not export it to override
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reshape)
                                                     name:NSViewGlobalFrameDidChangeNotification
                                                   object:self];
    }

    return self;
}


- (id)initWithFrame:(NSRect)frameRect
{
    self = [self initWithFrame:frameRect shareContext:nil];
    return self;
}


- (void)lockFocus
{
    [super lockFocus];
    if ( [[self openGLContext] view] != self )
    {
        [[self openGLContext] setView:self];
    }
}


- (void)reshape
{
    // This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
    // Add a mutex around to avoid the threads accessing the context simultaneously
    CGLLockContext( [[self openGLContext] CGLContextObj] );

//    [self setWantsBestResolutionOpenGLSurface:NO];
//    NSRect backingBounds = [self convertRectToBacking:self.bounds];

    // Delegate to the scene object to update for a change in the view size
    [[controller scene] setViewportRect:self.bounds];
    [controller scene].generateRandomDrops = [[NSUserDefaults standardUserDefaults] boolForKey:kGenerateRandomWaves];

    [[self openGLContext] update];

    CGLUnlockContext( [[self openGLContext] CGLContextObj] );
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Ignore if the display link is still running
    if ( !CVDisplayLinkIsRunning( displayLink ))
    {
        [self drawView];
    }
}


- (void)drawView
{
    // This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
    // Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
    // Add a mutex around to avoid the threads accessing the context simultaneously
    CGLLockContext( [[self openGLContext] CGLContextObj] );

    // Make sure we draw to the right context
    [[self openGLContext] makeCurrentContext];

    // Delegate to the scene object for rendering
    [[controller scene] render];
    [[self openGLContext] flushBuffer];

    CGLUnlockContext( [[self openGLContext] CGLContextObj] );
}


- (BOOL)acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}


- (void)keyDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling key events
    [controller keyDown:theEvent];
}


- (void)mouseDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling mouse events
    [controller mouseDown:theEvent];
}


- (void)startAnimation
{
    if ( displayLink && !CVDisplayLinkIsRunning( displayLink ))
    {
        CVDisplayLinkStart( displayLink );
    }
}


- (void)stopAnimation
{
    if ( self.isAnimating )
    {
        CVDisplayLinkStop( displayLink );
    }
}


- (BOOL)isAnimating
{
    return displayLink && CVDisplayLinkIsRunning( displayLink );
}


- (void)dealloc
{
    // Stop and release the display link
    CVDisplayLinkStop( displayLink );
    CVDisplayLinkRelease( displayLink );

    // Destroy the context
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewGlobalFrameDidChangeNotification
                                                  object:self];
}


@end
