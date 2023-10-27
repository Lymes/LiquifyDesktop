//
//  Scene.h
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class Texture;


@interface Scene:NSObject

@property (assign, nonatomic) BOOL generateRandomDrops;
@property (assign, nonatomic) BOOL followMousePointer;


- (void)setupGL;
- (void)setViewportRect:(NSRect)bounds;
- (void)update;
- (void)render;
- (void)tearDown;


- (void)reloadWallpaper;
- (void)reloadWallpaperFromURL:(NSURL *)url;

- (void)randomDrops;
- (void)setMouseLocation:(CGPoint)location;


@end
