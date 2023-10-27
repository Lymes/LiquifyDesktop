//
//  Texture.h
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Texture:NSObject {
    
    GLuint _texId;
    
}

- (id)initWithWallpaper;
- (id)initWithPath:(NSString *)path;


- (BOOL)reloadWallpaper;
- (BOOL)reloadWallpaperFromURL:(NSURL *)url;
- (GLuint)name;

+ (CGWindowID)getDesktopWindowId;

+ (CGImageRef)desktopImage;

@end
