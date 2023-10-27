//
//  MyOpenGLView.h
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

@class MainController;


@interface MyOpenGLView : NSOpenGLView {
	
	NSOpenGLContext *openGLContext;
	NSOpenGLPixelFormat *pixelFormat;
	
	MainController *controller;
	CVDisplayLinkRef displayLink;
}

@property BOOL isOccluded;
@property (assign, nonatomic, readonly) BOOL isAnimating;


- (id) initWithFrame:(NSRect)frameRect;
- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context;

- (NSOpenGLContext*) openGLContext;

- (void) setMainController:(MainController*)theController;

- (void) drawView;

- (void) startAnimation;
- (void) stopAnimation;

@end
