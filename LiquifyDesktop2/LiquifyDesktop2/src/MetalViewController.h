//
//  ViewController.h
//  MetalAcqua
//
//  Created by Leonid Mesentsev on 18/11/2018.
//  Copyright © 2018 Bridge Comm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

@interface MetalViewController : NSViewController

@property MTKView *metalView;
@property (assign, nonatomic) BOOL generateRandomDrops;
@property (assign, nonatomic) BOOL followMousePointer;


- (void)setMouseLocation:(CGPoint)location;

- (void)reloadWallpaper;

@end

