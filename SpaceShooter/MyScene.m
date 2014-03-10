//
//  MyScene.m
//  SpaceShooter
//
//  Created by Ankita Kalangutkar on 14/02/14.
//  Copyright (c) 2014 creative capsule. All rights reserved.
//

#import "MyScene.h"
#define kNumAsteroids 15
#define kNumLasers 5

@implementation MyScene
{
    // for asteroids
    NSMutableArray *asteroids;
    int nextAsteroid;
    double nextAsteroidSpawn;

    // for lasers
    NSMutableArray *shipLasers;
    int nextShipLaser;
    
    // for collision detection, provide a ship live
    int lives;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        NSLog(@"SKScene:initWithSize %f x %f",size.width,size.height);
        
        self.backgroundColor = [SKColor blackColor];
        // define edge loop to the ship, so that it does not move out of the screen
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        
#pragma mark - TBD - Game Backgrounds
        // implementing parallax effect
        NSArray *parallaxBackground = @[@"bg_galaxy.png", @"bg_planetsunrise.png", @"bg_spacialanomaly.png", @"bg_spacialanomaly2.png"];
        CGSize planetSizes = CGSizeMake(200, 200);
        self.parallaxNodeBackground = [[FMMParallaxNode  alloc] initWithBackgrounds:parallaxBackground size:planetSizes pointsPerSecondSpeed:10.0];
        self.parallaxNodeBackground.position = CGPointMake(size.width/2, size.height/2);
        [self.parallaxNodeBackground randomizeNodesPositions];
        [self addChild:self.parallaxNodeBackground];
        
        // now create space dust
        NSArray *parallaxBackgroungSpaceDust = @[@"bg_front_spacedust.png", @"bg_front_spacedust.png"];
        self.parallaxSpaceDust = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackgroungSpaceDust size:size pointsPerSecondSpeed:25.0];
        [self addChild:self.parallaxSpaceDust];
        
#pragma mark - Setup Sprite for the ship
        
        self.ship = [SKSpriteNode spriteNodeWithImageNamed:@"SpaceFlier_sm_1.png"];
        self.ship.position = CGPointMake(self.frame.size.width *0.1, CGRectGetMidY(self.frame));
        
        //move the ship using the spritekit physics engine
        //1. create a rect physics body same size as the ship
        self.ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.ship.frame.size];
        
        //2. body subjected to collision n other outside forces
        self.ship.physicsBody.dynamic = YES;
        
        //3. dont drop the ship to the ground
//        self.ship.physicsBody.affectedByGravity = NO;
        
        //4. give the ship arbitrary mass, so that its movement feels natural
        self.ship.physicsBody.mass = 0.02;
        
        [self addChild:self.ship];
        
#pragma mark - TBD - Setup the asteroids
        asteroids = [[NSMutableArray alloc] initWithCapacity:kNumAsteroids];
        for (int i=0; i<kNumAsteroids; i++)
        {
            SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
            asteroid.hidden = YES;
            [asteroid setXScale:0.5];
            [asteroid setYScale:0.5];
            [asteroids addObject:asteroid];
            [self addChild:asteroid];
        }
        
#pragma mark - TBD - Setup the lasers
        shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
        for (int i=0; i<kNumLasers; i++)
        {
            SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_blue"];
            shipLaser.hidden = YES;
            [shipLasers addObject:shipLaser];
            [self addChild:shipLaser];
        }
        
#pragma mark - TBD - Setup the Accelerometer to move the ship
        // initialize CMMotionManager instance
        self.motionManager = [[CMMotionManager alloc] init];
        
#pragma mark - TBD - Setup the stars to appear as particles
        [self addChild:[self loadEmitterNode:@"stars1"]];
        [self addChild:[self loadEmitterNode:@"stars2"]];
        [self addChild:[self loadEmitterNode:@"stars3"]];
        
#pragma mark - TBD - Start the actual game
        // start the game with accelerometer or with touch
        [self startTheGame];
    }
    return self;
}

-(void) startMonitoringAcceleration
{
    if (self.motionManager.accelerometerAvailable)
    {
        [self.motionManager startAccelerometerUpdates];
        NSLog(@"accelerometer updates on...");
    }
}

-(void) stopMonitoringAcceleration
{
    if (self.motionManager.accelerometerAvailable && self.motionManager.accelerometerActive)
    {
        [self.motionManager stopAccelerometerUpdates];
        NSLog(@"accelerometer updates off...");
    }
}


-(void) updateShipPositionFromMotionMonitor
{
    CMAccelerometerData *data = self.motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.2)
    {
        [_ship.physicsBody applyForce:CGVectorMake(0.0, 10.0 * data.acceleration.x)];
//         NSLog(@"acceleration value = %f",data.acceleration.x);
    }
}

-(void) startTheGame
{
    nextAsteroidSpawn = 0;
    for (SKSpriteNode *asteroid in asteroids) {
        asteroid.hidden = YES;
    }
    for (SKSpriteNode *shipLaser in shipLasers) {
        shipLaser.hidden = YES;
    }
    self.ship.hidden = NO;
    self.ship.position = CGPointMake(self.frame.size.width *0.1, CGRectGetMidY(self.frame));
//    [self startMonitoringAcceleration];
    
    // continuously fire the laser beam
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireShipLaser) userInfo:nil repeats:YES];
}

#pragma mark -- loadEmitterNode
-(SKEmitterNode *) loadEmitterNode: (NSString *) emitterFileName
{
    SKEmitterNode *emitterNode = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:emitterFileName ofType:@"sks"]];
    emitterNode.particlePosition = CGPointMake(self.size.width/2.0, self.size.height/2.0);
    emitterNode.particlePositionRange = CGVectorMake(self.size.width+100, self.size.height);
    return emitterNode;
}

- (void)fireShipLaser
{
    // fire bullet on touch
    // pick up the bullet from pre made bullets
    SKSpriteNode *shipLaser = [shipLasers objectAtIndex:nextShipLaser];
    nextShipLaser++;
    if (nextShipLaser >= shipLasers.count) {
        nextShipLaser = 0;
    }
    
    // set the laser position to the ships position
    shipLaser.position = CGPointMake(self.ship.position.x+shipLaser.size.width/2, self.ship.position.y);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    //setup the end position of the laser
    CGPoint location = CGPointMake(self.frame.size.width, self.ship.position.y);
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    
    // aftr performing above action
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^()
                                 {
                                     shipLaser.hidden = YES;
                                 }];
    // provide action sequence
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    //perform action
    [shipLaser runAction:moveLaserActionWithDone];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [self fireShipLaser];
    NSLog(@"touchesBegan");
    self.ship.physicsBody.affectedByGravity = NO;
    SKAction * moveUp = [SKAction moveByX:0 y:self.frame.size.height duration:1.5];
    [self.ship runAction:moveUp];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded");
//    self.ship.physicsBody.affectedByGravity = YES;
    SKAction *moveDown = [SKAction moveByX:0 y:-self.frame.size.height duration:1.5];
    [self.ship runAction:moveDown];
}

- (float)randomValueBetween:(float)low andValue:(float)high
{
     return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
//    NSLog(@"currentTime %f", currentTime);
    [self.parallaxSpaceDust update:currentTime];
    [self.parallaxNodeBackground update:currentTime];
    [self updateShipPositionFromMotionMonitor];
    
    // moving asteroids towards ship
    double currTime = CACurrentMediaTime();
    if (currTime > nextAsteroidSpawn)
    {
        float randSecs= [self randomValueBetween:0.20 andValue:1.0];
        nextAsteroidSpawn = randSecs + currTime;
        
        // get random values for y axis
        float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];
        //rand time duration
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];
        
        SKSpriteNode *asteroid = [asteroids objectAtIndex:nextAsteroid];
        nextAsteroid++;
        
        if (nextAsteroid>= asteroids.count)
        {
            nextAsteroid = 0;
        }
        
        [asteroid removeAllActions];
        asteroid.position = CGPointMake(self.frame.size.width+asteroid.size.width/2, randY);
        asteroid.hidden = NO;
        
        CGPoint location = CGPointMake(-self.frame.size.width-asteroid.size.width, randY);
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^()
                                {
                                    asteroid.hidden = YES;
                                }];
        SKAction *moveAsteroidActionWithDone = [SKAction sequence:@[moveAction,doneAction]];
        [asteroid runAction:moveAsteroidActionWithDone withKey:@"asteroidMoving"];
    }
    
    // check for laser collision
    [self laserAsteroidCollision];
}

-(void) laserAsteroidCollision
{
    //1. if asteroid is hidden, continue
    for (SKSpriteNode *asteroid in asteroids)
    {
        if (asteroid.hidden) {
            continue;
        }

    //2. if laser is hidden, continue
        for (SKSpriteNode *shipLaser in shipLasers)
        {
            if (shipLaser.hidden) {
                continue;
            }
              //3. if laser hit asteroid, remove asteroid
            if ([shipLaser intersectsNode:asteroid]) {
                shipLaser.hidden = YES;
                asteroid.hidden = YES;
                
                continue;
            }
        }
        //4. if ship hits asteroid rmove ship
        if ([self.ship intersectsNode:asteroid])
        {
            asteroid.hidden = YES;
            //1. blink n remove ship
            SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],
                                                   [SKAction fadeInWithDuration:0.1]]];
            SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
            //2. decreement the ship lives
            [self.ship runAction:blinkForTime];
            lives--;
        }

        
    }
    
    

}

@end
