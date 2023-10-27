//
//  Texture.m
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import "Texture.h"
#import <OpenGL/glu.h>
#import <GLKit/GLKit.h>

static GLKTextureInfo *_textureInfo;


@interface Texture (PrivateMethods)

- (BOOL)loadFromPath:(NSString *)path;
- (BOOL)loadFromWindowId:(CGWindowID)wid;

@end


@implementation Texture


+ (CGWindowID)getDesktopWindowId
{
    int minLevel = 10000;
    CGWindowID windowID = -1;

    //SInt32 version = 0;
    //Gestalt( gestaltSystemVersion, &version );
    //NSString *app = ( version < 0x1070 ) ? @"Window Server":@"Dock";
        
    NSOperatingSystemVersion ver = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *app = ( ver.minorVersion < 7 ) ? @"Window Server":@"Dock";

    CFArrayRef windowList = CGWindowListCopyWindowInfo( kCGWindowListOptionOnScreenBelowWindow, kCGNullWindowID );
    for ( int i = 0; i < CFArrayGetCount( windowList ); i++ )
    {
        NSDictionary *data = (__bridge NSDictionary *)CFArrayGetValueAtIndex( windowList, i );
        NSString *appName = [data objectForKey:(NSString *)kCGWindowOwnerName];
        if ( [appName isEqualToString:app] )
        {
            int level = [[data objectForKey:(NSString *)kCGWindowLayer] intValue];
            if ( level < minLevel )
            {
                windowID = [[data objectForKey:(NSString *)kCGWindowNumber] unsignedIntValue];
                minLevel = level;
            }
        }
    }
    CFRelease( windowList );
    return windowID;
}


- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if ( self )
    {
        _texId = 0;
        [self loadFromPath:path];
    }
    return self;
}


- (id)initWithWallpaper
{
    self = [super init];
    if ( self )
    {
        _texId = 0;
        [self reloadWallpaper];
    }
    return self;
}


- (BOOL)reloadWallpaper
{
    CGWindowID windowID = [Texture getDesktopWindowId];

    if ( windowID != -1 )
    {
        if ( [self loadFromWindowId:windowID] )
        {
            return YES;
        }
    }
    return NO;
}


- (BOOL)reloadWallpaperFromURL:(NSURL *)url
{
    if ( [self loadFromURL:url] )
    {
        return YES;
    }
    return NO;
}


- (GLuint)name
{
    return _texId;
}


+ (CGImageRef)desktopImage
{
    CGImageRef image;

    int wid = [self getDesktopWindowId];

    // snag the image
    image = CGWindowListCreateImage( CGRectNull, kCGWindowListOptionIncludingWindow,
                                     wid, kCGWindowImageBoundsIgnoreFraming );

    // little bit of error checking
    if ( CGImageGetWidth( image ) <= 1 )
    {
        CGImageRelease( image );
        NSLog( @"Error: CGWindowListCreateImage()" );
        return nil;
    }

    return image;
}


- (BOOL)loadFromWindowId:(CGWindowID)wid
{
    CGImageRef image;
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;

    // snag the image
    image = CGWindowListCreateImage( CGRectNull, kCGWindowListOptionIncludingWindow,
                                     wid, kCGWindowImageBoundsIgnoreFraming );

    // little bit of error checking
    if ( CGImageGetWidth( image ) <= 1 )
    {
        CGImageRelease( image );
        NSLog( @"Error: CGWindowListCreateImage()" );
        return NO;
    }

    NSError *error = nil;
    _textureInfo = [GLKTextureLoader textureWithCGImage:image options:nil error:&error];
    if ( error )
    {
        CGImageRelease( image );
        NSLog( @"Error: textureWithCGImage: %@", error.localizedDescription );
        return NO;
    }
    _texId = _textureInfo.name;
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, _texId );


    return YES;
    
    GLsizei imageWidth = (GLsizei)CGImageGetHeight( image );
    GLsizei imageHeight = (GLsizei)CGImageGetWidth( image );

//    float ratio = imageHeight / imageWidth;
//    imageWidth = 1000;
//    imageHeight = imageWidth * ratio;

    GLubyte *imageData = (GLubyte *)calloc( imageWidth * imageHeight * 4, sizeof( GLubyte ));

    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate( imageData, imageWidth, imageHeight, 8, 4 * imageWidth, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
    CGColorSpaceRelease( colorSpace );

    // Core Graphics referential is upside-down compared to OpenGL referential
    // Flip the Core Graphics context here
    // An alternative is to use flipped OpenGL texture coordinates when drawing textures

    CGContextTranslateCTM( context, imageWidth, 0 );
    CGContextRotateCTM( context, M_PI_2 );

    //        CGContextTranslateCTM( context, 0.0, imageWidth );
    //        CGContextScaleCTM( context, 1.0, -1.0 );

    // Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
    CGContextSetBlendMode( context, kCGBlendModeCopy );

    CGContextDrawImage( context, CGRectMake( 0, 0, imageHeight, imageWidth ), image );

    CGContextRelease( context );
    CGImageRelease( image );

    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( GL_TEXTURE_2D, 0 );

    if ( !_texId )
    {
        glGenTextures( 1, &_texId );
        GLenum e = glGetError();
        if ( e != GL_NO_ERROR )
        {
            NSLog( @"glGenTextures() error %d", e );
            free( imageData );
            return NO;
        }

        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );

        // Setup texture parameters
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE );
        glPixelStorei( GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE );

        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }
    else
    {
        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }

    GLint err = glGetError();
    if ( err )
    {
        NSLog( @"Error of texture creation: 0x%x", err );
    }

    free( imageData );
    glBindTexture( GL_TEXTURE_2D, _texId );

    return YES;
}


- (BOOL)loadFromPath:(NSString *)path
{
    NSURL *url = nil;
    CGImageSourceRef src;
    CGImageRef image;
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;

    url = [NSURL fileURLWithPath:path];
    src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL );

    if ( !src )
    {
        NSLog( @"No image" );
        return NO;
    }

    image = CGImageSourceCreateImageAtIndex( src, 0, NULL );
    CFRelease( src );

    GLsizei imageWidth = (GLsizei)CGImageGetWidth( image );
    GLsizei imageHeight = (GLsizei)CGImageGetHeight( image );

    GLubyte *imageData = (GLubyte *)calloc( imageWidth * imageHeight * 4, sizeof( GLubyte ));

    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate( imageData, imageWidth, imageHeight, 8, 4 * imageWidth, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
    CGColorSpaceRelease( colorSpace );

    // Core Graphics referential is upside-down compared to OpenGL referential
    // Flip the Core Graphics context here
    // An alternative is to use flipped OpenGL texture coordinates when drawing textures
    CGContextTranslateCTM( context, 0.0, imageHeight );
    CGContextScaleCTM( context, 1.0, -1.0 );

    // Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
    CGContextSetBlendMode( context, kCGBlendModeCopy );

    CGContextDrawImage( context, CGRectMake( 0, 0, imageWidth, imageHeight ), image );

    CGContextRelease( context );
    CGImageRelease( image );

    if ( !_texId )
    {
        glGenTextures( 1, &_texId );
        GLenum e = glGetError();
        if ( e != GL_NO_ERROR )
        {
            NSLog( @"glGenTextures() error %d", e );
            free( imageData );
            return NO;
        }

        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );

        // Setup texture parameters
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE );
        glPixelStorei( GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE );

        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }
    else
    {
        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }

    free( imageData );
    glBindTexture( GL_TEXTURE_2D, 0 );

    return YES;
}


- (BOOL)loadFromURL:(NSURL *)url
{
    CGImageSourceRef src;
    CGImageRef image;
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;

    NSLog( @"%@", url );

    src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL );

    if ( !src )
    {
        NSLog( @"No image" );
        return NO;
    }

    image = CGImageSourceCreateImageAtIndex( src, 0, NULL );
    CFRelease( src );

    GLsizei imageWidth = (GLsizei)CGImageGetWidth( image );
    GLsizei imageHeight = (GLsizei)CGImageGetHeight( image );

    GLubyte *imageData = (GLubyte *)calloc( imageWidth * imageHeight * 4, sizeof( GLubyte ));

    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate( imageData, imageWidth, imageHeight, 8, 4 * imageWidth, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
    CGColorSpaceRelease( colorSpace );

    // Core Graphics referential is upside-down compared to OpenGL referential
    // Flip the Core Graphics context here
    // An alternative is to use flipped OpenGL texture coordinates when drawing textures
    CGContextTranslateCTM( context, 0.0, imageHeight );
    CGContextScaleCTM( context, 1.0, -1.0 );

    // Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
    CGContextSetBlendMode( context, kCGBlendModeCopy );

    CGContextDrawImage( context, CGRectMake( 0, 0, imageWidth, imageHeight ), image );

    CGContextRelease( context );
    CGImageRelease( image );

    if ( !_texId )
    {
        glGenTextures( 1, &_texId );
        GLenum e = glGetError();
        if ( e != GL_NO_ERROR )
        {
            NSLog( @"glGenTextures() error %d", e );
            free( imageData );
            return NO;
        }

        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );

        // Setup texture parameters
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE );
        glPixelStorei( GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE );

        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }
    else
    {
        // Bind the texture
        glBindTexture( GL_TEXTURE_2D, _texId );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, imageData );
    }

    free( imageData );
    glBindTexture( GL_TEXTURE_2D, 0 );

    return YES;
}


- (void)dealloc
{
    glDeleteTextures( 1, &_texId );
}


@end
