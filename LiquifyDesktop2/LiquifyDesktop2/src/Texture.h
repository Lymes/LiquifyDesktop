//
//  Texture.h
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>


@interface Texture: NSObject

@property (nonatomic, readonly) id<MTLTexture> texture;

- (id)initWithDevice:(id<MTLDevice>)device;

- (BOOL)reloadWallpaper;
- (BOOL)reloadWallpaperFromURL:(NSURL *)url;

+ (CGWindowID)getDesktopWindowId;
+ (CGImageRef)desktopImage;

@end
