//
//  Texture.m
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//

#import "Texture.h"


@interface Texture () {
    
    id<MTLDevice> _device;
}

- (BOOL)loadFromWindowId:(CGWindowID)wid;

@end


@implementation Texture


+ (CGWindowID)getDesktopWindowId
{
    int minLevel = 10000;
    CGWindowID windowID = -1;

    CFArrayRef windowList = CGWindowListCopyWindowInfo( kCGWindowListOptionOnScreenBelowWindow, kCGNullWindowID );
    for ( int i = 0; i < CFArrayGetCount( windowList ); i++ )
    {
        NSDictionary *data = (__bridge NSDictionary *)CFArrayGetValueAtIndex( windowList, i );
        NSString *appName = [data objectForKey:(NSString *)kCGWindowOwnerName];
        if ( [appName isEqualToString:@"Dock"] )
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


- (id)initWithDevice:(id<MTLDevice>)device;
{
    self = [super init];
    if ( self )
    {
        _texture = 0;
        _device = device;
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
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;

    // snag the image
    CGImageRef image = CGWindowListCreateImage( CGRectNull, kCGWindowListOptionIncludingWindow,
                                     wid, kCGWindowImageBoundsIgnoreFraming );

    // little bit of error checking
    if ( CGImageGetWidth( image ) <= 1 )
    {
        CGImageRelease( image );
        NSLog( @"Error: CGWindowListCreateImage()" );
        return NO;
    }
    /*
    NSError *error = nil;
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:_device];
    _texture = [loader newTextureWithCGImage:image options:nil error:&error];
    if ( error )
    {
        CGImageRelease( image );
        NSLog( @"Error: textureWithCGImage: %@", error.localizedDescription );
        return NO;
    }
    CGImageRelease( image );
     */
    int imageWidth = (int)CGImageGetWidth( image );
    int imageHeight = (int)CGImageGetHeight( image );
    
    void *imageData = (void *)calloc( imageWidth * imageHeight * 4, 1 );
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate( imageData, imageHeight, imageWidth, 8, 4 * imageHeight, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
    CGColorSpaceRelease( colorSpace );
    
    CGContextTranslateCTM( context, imageHeight, 0 );
    CGContextRotateCTM( context, M_PI_2 );
    
    // Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
    CGContextSetBlendMode( context, kCGBlendModeCopy );
    CGContextDrawImage( context, CGRectMake( 0, 0, imageWidth, imageHeight ), image );
    CGContextRelease( context );
    CGImageRelease( image );
    
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                          width:imageHeight
                                                                                         height:imageWidth
                                                                                      mipmapped:NO];
    _texture = [_device newTextureWithDescriptor:descriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, imageHeight, imageWidth);
    [_texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:4 * imageHeight];
    
    free(imageData);
    return YES;
}


- (BOOL)loadFromURL:(NSURL *)url
{
    CGImageSourceRef src;
    CGImageRef image;
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;
    src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL );
    if ( !src )
    {
        NSLog( @"No image" );
        return NO;
    }
    
    image = CGImageSourceCreateImageAtIndex( src, 0, NULL );
    CFRelease( src );
    
    int imageWidth = (int)CGImageGetWidth( image );
    int imageHeight = (int)CGImageGetHeight( image );
    
    void *imageData = (void *)calloc( imageWidth * imageHeight * 4, 1 );
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate( imageData, imageHeight, imageWidth, 8, 4 * imageHeight, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host );
    CGColorSpaceRelease( colorSpace );
    
    CGContextTranslateCTM( context, imageHeight, 0 );
    CGContextRotateCTM( context, M_PI_2 );
    
    // Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
    CGContextSetBlendMode( context, kCGBlendModeCopy );
    CGContextDrawImage( context, CGRectMake( 0, 0, imageWidth, imageHeight ), image );
    CGContextRelease( context );
    CGImageRelease( image );
    
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                          width:imageHeight
                                                                                         height:imageWidth
                                                                                      mipmapped:NO];
    _texture = [_device newTextureWithDescriptor:descriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, imageHeight, imageWidth);
    [_texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:4 * imageHeight];
    
    free(imageData);
    return YES;
}


- (void)dealloc
{
    _texture = 0;
}


@end
