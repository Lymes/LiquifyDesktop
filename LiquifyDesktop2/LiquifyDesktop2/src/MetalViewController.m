//
//  ViewController.m
//  MetalAcqua
//
//  Created by Leonid Mesentsev on 18/11/2018.
//  Copyright © 2018 Bridge Comm. All rights reserved.
//

#import "MetalViewController.h"
#import "MainController.h"
#import "RippleModel.h"
#import "Texture.h"


@interface MetalViewController () {
    
    id<MTLDevice>  _device;

    id<MTLCommandQueue>  _commandQueue;
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLComputePipelineState> _computePipelineState;
    Texture *_texture;
    
    id<MTLBuffer> _vertexBuffer;
    id<MTLBuffer> _texcoordsBuffer;
    id<MTLBuffer> _indexBuffer;

    id<MTLBuffer> _rippleSourceBuffer;
    id<MTLBuffer> _rippleDestBuffer;
    id<MTLBuffer> _rippleCoeffBuffer;
    id<MTLBuffer> _modelDataBuffer;

    RippleModel *_model;
    
    id _mouseEventsMonitor;
    dispatch_queue_t _timerQueue;
    dispatch_source_t _randomDropTimer;
}

@property (nonatomic) dispatch_semaphore_t semaphore;

@end


@implementation MetalViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _device = nil;
    /*
    NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
    // Low power device is sufficient - try to use it!
    for ( id<MTLDevice> device in devices )
    {
        if (device.isLowPower)
        {
            _device = device;
            break;
        }
    }
    */
    // below: probably not necessary since there is always
    // integrated GPU, but doesn't hurt.
    if (_device == nil)
    {
        _device = MTLCreateSystemDefaultDevice();
    }
    
    CGRect frame = self.view.bounds;
    _metalView = [[MTKView alloc] initWithFrame:frame device:_device];
    _metalView.delegate = (id<MTKViewDelegate>)self;
    _metalView.framebufferOnly = YES;
    _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:_metalView];
    
    _semaphore = dispatch_semaphore_create(1);
    _commandQueue = [_metalView.device newCommandQueue];
    
    _texture = [[Texture alloc] initWithDevice:_device];
    [_texture reloadWallpaper];
    
    id<MTLLibrary> library = _device.newDefaultLibrary;
    
    NSError *error = nil;
    // RENDER PIPELINE
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.sampleCount = 1;
    pipelineDescriptor.colorAttachments[0].pixelFormat = _texture.texture.pixelFormat;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertexTexture"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentTexture"];
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if ( error )
    {
        NSLog(@"Error: %@", error.localizedDescription);
    }
    
    // COMPUTING PIPELINE
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"runSimulation"];
    _computePipelineState = [_device  newComputePipelineStateWithFunction:kernelFunction error:&error];
    if ( error )
    {
        NSLog(@"Error: %@", error.localizedDescription);
    }
    
    _timerQueue = dispatch_queue_create("com.lymes.LiquifyDesktop2.timerQueue", 0);
    _randomDropTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timerQueue);
    dispatch_source_set_timer(_randomDropTimer, DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC, NSEC_PER_SEC / 10);
    dispatch_source_set_event_handler(_randomDropTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self randomDrops];
        });
    });
}


- (void)viewWillAppear
{
    [super viewWillAppear];
    [self mtkView:_metalView drawableSizeWillChange:self.view.bounds.size];
}


- (void)reloadWallpaper
{
    _metalView.paused = YES;
    [_texture reloadWallpaper];
    _metalView.paused = NO;
}


- (void)setGenerateRandomDrops:(BOOL)generateRandomDrops
{
    _generateRandomDrops = generateRandomDrops;
    if ( _generateRandomDrops )
    {
        dispatch_resume(_randomDropTimer);
    }
    else
    {
        dispatch_suspend(_randomDropTimer);
    }
}


- (void)setFollowMousePointer:(BOOL)followMousePointer
{
    _followMousePointer = followMousePointer;
    if ( _followMousePointer )
    {
        _mouseEventsMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged) handler:^( NSEvent *mouseEvent ) {
            [self setMouseLocation:[NSEvent mouseLocation]];
        }];
    }
    else
    {
        [NSEvent removeMonitor:_mouseEventsMonitor];
    }
}


- (void)randomDrops
{
    if ( _generateRandomDrops )
    {
        CGPoint randomPoint = CGPointMake( rand() % (int)self.view.bounds.size.width,
                                          rand() % (int)self.view.bounds.size.height );
        
        if ( _model )
        {
            [self initiateRippleAtLocation:randomPoint];
        }
    }
}


- (void)setMouseLocation:(CGPoint)location
{
    if ( _followMousePointer )
    {
        [self initiateRippleAtLocation:location];
    }
}


- (void)mouseDown:(NSEvent *)event
{
    NSPoint curPoint = [self.view convertPoint:[event locationInWindow] fromView:nil];
    [self initiateRippleAtLocation:curPoint];
}


- (void)initiateRippleAtLocation:(CGPoint)location
{
    ModelData modelData = _model.getModelData;
    modelData.location.x = location.x / self.view.bounds.size.width;
    modelData.location.y = 1.0 - location.y / self.view.bounds.size.height;
    memcpy(_modelDataBuffer.contents, &modelData, sizeof(ModelData));
}


- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _model = [[RippleModel alloc] initWithScreenWidth:size.width/2 screenHeight:size.height/2 meshFactor:8 touchRadius:4 textureWidth:(unsigned)_texture.texture.width textureHeight:(unsigned)_texture.texture.height];
    _vertexBuffer = [_device newBufferWithBytes:_model.getVertices length:_model.getVertexSize options:MTLResourceCPUCacheModeDefaultCache];
    _texcoordsBuffer = [_device newBufferWithBytes:_model.getTexCoords length:_model.getVertexSize options:MTLResourceCPUCacheModeDefaultCache];
    _indexBuffer = [_device newBufferWithBytes:_model.getIndices length:_model.getIndexSize options:MTLResourceCPUCacheModeDefaultCache];
    _rippleSourceBuffer = [_device newBufferWithBytes:_model.getRippleSource length:_model.getRippleSize options:MTLResourceCPUCacheModeDefaultCache];
    _rippleDestBuffer = [_device newBufferWithBytes:_model.getRippleDest length:_model.getRippleSize options:MTLResourceCPUCacheModeDefaultCache];
    _rippleCoeffBuffer = [_device newBufferWithBytes:_model.getRippleCoeff length:_model.getRippleCoeffSize options:MTLResourceCPUCacheModeDefaultCache];
    ModelData modelData = _model.getModelData;
    _modelDataBuffer = [_device newBufferWithBytes:&modelData length:sizeof(ModelData) options:MTLResourceStorageModeShared];
    
    self.generateRandomDrops = [[NSUserDefaults standardUserDefaults] boolForKey:kGenerateRandomWaves];
}


- (void)drawInMTKView:(MTKView *)view
{
    static int counter = 0;
    
    @autoreleasepool
    {
        if (dispatch_semaphore_wait(_semaphore, 0)) { return; }
        
        MTLRenderPassDescriptor *currentRenderPassDescriptor = _metalView.currentRenderPassDescriptor;
        id<CAMetalDrawable> currentDrawable = _metalView.currentDrawable;
        id<MTLCommandBuffer> commandBuffer = _commandQueue.commandBuffer;
        
        if ( !_model || !currentRenderPassDescriptor || !currentDrawable )
        {
            dispatch_semaphore_signal(_semaphore);
            return;
        }

        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder pushDebugGroup:@"ComputeModel"];
        [computeEncoder setComputePipelineState:_computePipelineState];
        [computeEncoder setBuffer:_texcoordsBuffer offset:0 atIndex:0];
        [computeEncoder setBuffer:_modelDataBuffer offset:0 atIndex:1];
        [computeEncoder setBuffer:_rippleDestBuffer offset:0 atIndex:(counter % 2) ? 2 : 3];
        [computeEncoder setBuffer:_rippleSourceBuffer offset:0 atIndex:(counter % 2) ? 3 : 2];
        [computeEncoder setBuffer:_rippleCoeffBuffer offset:0 atIndex:4];
        counter++;
        [computeEncoder popDebugGroup];
        
        MTLSize threadsPerThreadgroup = MTLSizeMake(1, 1, 1);
        MTLSize threadgroupsPerGrid = MTLSizeMake(1, 1, 1);
        [computeEncoder dispatchThreadgroups:threadgroupsPerGrid
                       threadsPerThreadgroup:threadsPerThreadgroup];
        [computeEncoder endEncoding];
                
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:currentRenderPassDescriptor];
        [renderEncoder pushDebugGroup:@"RenderFrame"];
        [renderEncoder setRenderPipelineState:_renderPipelineState];
        [renderEncoder setVertexBuffer:_vertexBuffer       offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:_texcoordsBuffer    offset:0 atIndex:1];
        [renderEncoder setFragmentTexture:_texture.texture atIndex:0];
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangleStrip indexCount:_model.getIndexCount indexType:MTLIndexTypeUInt16 indexBuffer:_indexBuffer indexBufferOffset:0 instanceCount:1];
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        
        __weak typeof(self) weakSelf = self;
        [commandBuffer addScheduledHandler:^(id<MTLCommandBuffer> _Nonnull cb) {
            dispatch_semaphore_signal(weakSelf.semaphore);
        }];
        
        [commandBuffer presentDrawable:currentDrawable];
        [commandBuffer commit];
    }
}


@end
