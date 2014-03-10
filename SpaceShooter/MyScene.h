//
//  MyScene.h
//  SpaceShooter
//

//  Copyright (c) 2014 creative capsule. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "FMMParallaxNode.h"
@import CoreMotion;

@interface MyScene : SKScene
@property (nonatomic,strong) SKSpriteNode *ship;
@property (nonatomic,strong) FMMParallaxNode *parallaxNodeBackground;
@property (nonatomic,strong) FMMParallaxNode *parallaxSpaceDust;
@property (nonatomic,strong) CMMotionManager *motionManager;
@end
