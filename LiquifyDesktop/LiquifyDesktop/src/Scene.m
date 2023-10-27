//
//  Scene.m
//  Liquify
//
//  Created by L.Y.Mesentsev on 4/16/12.
//  Copyright 2012 L.Y.Mesentsev. All rights reserved.
//


#import "Scene.h"
#import "Texture.h"
#import "RippleModel.h"



@interface Scene () {

    RippleModel *_model;

    GLuint _positionVBO;
    GLuint _indexVBO;
    GLuint _texCoordVBO;

    Texture *_background;
    NSRect _screenBounds;
}

@end


@implementation Scene



#pragma mark -
#pragma mark Random drops


- (void)setGenerateRandomDrops:(BOOL)generateRandomDrops
{
    _generateRandomDrops = generateRandomDrops;
    [self randomDrops];
}


- (void)randomDrops
{
    if ( _generateRandomDrops )
    {
        CGPoint randomPoint = CGPointMake( rand() % (int)_screenBounds.size.height,
                                           rand() % (int)_screenBounds.size.width );

        randomPoint.x /= (float)_screenBounds.size.height;
        randomPoint.y /= (float)_screenBounds.size.width;
        [_model initiateRippleAtLocation:randomPoint];
        [self performSelector:@selector(randomDrops) withObject:nil afterDelay:2];
    }
}


#pragma mark -
#pragma mark Wallpaper


- (void)reloadWallpaper
{
    [_background reloadWallpaper];
}


- (void)reloadWallpaperFromURL:(NSURL *)url
{
    [_background reloadWallpaperFromURL:url];
}


#pragma mark -
#pragma mark Follow mouse


- (void)setMouseLocation:(CGPoint)location
{
    if ( _followMousePointer )
    {
        float x = location.x / (float)_screenBounds.size.width;
        location.x = location.y / (float)_screenBounds.size.height;
        location.y = x;
        [_model initiateRippleAtLocation:location];
    }
}


#pragma mark -
#pragma mark VBO setup


- (void)setup_indexVBOs
{
    int size = [_model getIndexSize];
    GLushort *indices = [_model getIndices];

    glGenBuffers( 1, &_indexVBO );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexVBO );
    glBufferData( GL_ELEMENT_ARRAY_BUFFER, size, indices, GL_STATIC_DRAW );
}


- (void)setup_positionVBOs
{
    int size = [_model getVertexSize];
    GLfloat *v = [_model getVertices];

    glGenBuffers( 1, &_positionVBO );
    glBindBuffer( GL_ARRAY_BUFFER, _positionVBO );
    glBufferData( GL_ARRAY_BUFFER, size, v, GL_STATIC_DRAW );

    glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof( GLfloat ), 0 );
}


- (void)setup_texCoordVBOs
{
    int size = [_model getVertexSize];
    GLfloat *coords = [_model getTexCoords];

    glGenBuffers( 1, &_texCoordVBO );
    glBindBuffer( GL_ARRAY_BUFFER, _texCoordVBO );
    glBufferData( GL_ARRAY_BUFFER, size, coords, GL_DYNAMIC_DRAW );
}


#pragma mark -
#pragma mark Life cycle


- (void)dealloc
{
    [self tearDown];
}


- (void)tearDown
{
    glDeleteBuffers( 1, &_indexVBO );
    glDeleteBuffers( 1, &_positionVBO );
    glDeleteBuffers( 1, &_texCoordVBO );
}


- (void)setupGL
{
    _background = [[Texture alloc] initWithWallpaper];

    glEnable( GL_DEPTH_TEST );
    glEnable( GL_TEXTURE_2D );
    glDepthFunc( GL_LESS );
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glClearColor( 0, 0, 0, 0 );

    glHint( GL_POLYGON_SMOOTH_HINT, GL_NICEST );
    glEnable( GL_MULTISAMPLE );

//    glEnable( GL_COLOR_MATERIAL );
//    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
//    glEnable( GL_LIGHTING );
//    glEnable( GL_LIGHT0 );
//    GLfloat lightPosition[] = { 2, 1.0, 1.0, 1.0 };
//    glLightfv( GL_LIGHT0, GL_POSITION, lightPosition );
//    glLightf( GL_LIGHT0, GL_CONSTANT_ATTENUATION, .1 );
}


- (void)setViewportRect:(NSRect)bounds
{
    _screenBounds = bounds;
    [self tearDown];

//    float ratio = bounds.size.width / bounds.size.height;
    _model = [[RippleModel alloc] initWithScreenWidth:bounds.size.width
                                         screenHeight:bounds.size.height
                                           meshFactor:10
                                          touchRadius:4
                                         textureWidth:bounds.size.height
                                        textureHeight:bounds.size.width];

    [self setup_indexVBOs];
    [self setup_positionVBOs];
    [self setup_texCoordVBOs];

    glViewport( 0, 0, bounds.size.width, bounds.size.height );

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glOrtho( -1, 1, -1, 1, -1, 1 );

    glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
    glLoadIdentity();                // and reset it

    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glEnableClientState( GL_VERTEX_ARRAY );

    glBindBuffer( GL_ARRAY_BUFFER, _texCoordVBO );
    glBufferData( GL_ARRAY_BUFFER, _model.getVertexSize, _model.getTexCoords, GL_DYNAMIC_DRAW );
    glTexCoordPointer( 2, GL_FLOAT, 0, (void *)0 );

    glBindBuffer( GL_ARRAY_BUFFER, _positionVBO );
    glVertexPointer( 2, GL_FLOAT, 0, (void *)0 );

    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexVBO );
}


- (void)update
{
    [_model runSimulation];
}


- (void)render
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glBindTexture(GL_TEXTURE_2D, _background.name);
    glBindBuffer( GL_ARRAY_BUFFER, _texCoordVBO );
    glBufferData( GL_ARRAY_BUFFER, _model.getVertexSize, _model.getTexCoords, GL_DYNAMIC_DRAW );

    glDrawElements( GL_TRIANGLE_STRIP, [_model getIndexCount], GL_UNSIGNED_SHORT, 0 );
    
    GLenum e = glGetError();
    if ( e != GL_NO_ERROR )
    {
        NSLog( @"glError() error 0x%x", e );
    }

}


@end
