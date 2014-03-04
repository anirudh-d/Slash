//
//  MyScene.m
//  Slash
//
//  Created by Anirudh Donakonda on 3/4/14.
//  Copyright (c) 2014 Anirudh Donakonda. All rights reserved.
//

#import "MyScene.h"
static const uint32_t boundry   =  0x1 << 1;
static const uint32_t catd      =  0x1 << 2;
static const uint32_t lined     =  0x1 << 3;

@implementation MyScene{
    NSMutableArray *myObjects;
    SKShapeNode *polygonBoundry,*lineCut;
    CGMutablePathRef pathToDraw;
    CGPoint lineCutFirstPoint,lineCutSecondPoint;
    int numberOfObjects;
}

-(id)initWithSize:(CGSize)size {
    
    if (self = [super initWithSize:size]) {
        
        /* Setup your scene here */
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.scaleMode = SKSceneScaleModeAspectFit;
        self.physicsWorld.gravity = CGVectorMake(0.0f,0.0f);
        
        /* Array that hold pointers to all random moving objects */
        myObjects = [[NSMutableArray alloc] init];
        
        pathToDraw = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw, NULL,0+10,0+10);
        CGPathAddLineToPoint(pathToDraw, NULL,0+10,self.size.height-10);
        CGPathAddLineToPoint(pathToDraw, NULL,self.size.width-10,self.size.height-10);
        CGPathAddLineToPoint(pathToDraw, NULL,self.size.width-10,0+10);
        CGPathAddLineToPoint(pathToDraw, NULL,0+10,0+10);
        
        polygonBoundry = [SKShapeNode node];
        polygonBoundry.name =@"lineCut";
        polygonBoundry.strokeColor = [SKColor redColor];
        polygonBoundry.path = pathToDraw;
        polygonBoundry.physicsBody.friction=0.0f;
        polygonBoundry.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromPath:pathToDraw];
        polygonBoundry.physicsBody.categoryBitMask = boundry;
        [self addChild:polygonBoundry];
        
        self.physicsWorld.contactDelegate = self;
        [self spawnObjects:5];
        
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch* touch = [touches anyObject];
    lineCutFirstPoint = [touch locationInNode:self];
    pathToDraw = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDraw, NULL, lineCutFirstPoint.x, lineCutFirstPoint.y);
    lineCut = [SKShapeNode node];
    lineCut.path = pathToDraw;
    lineCut.strokeColor = [SKColor redColor];
    [self addChild:lineCut];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    lineCutSecondPoint = [touch locationInNode:self];
    
    pathToDraw = CGPathCreateMutable();
    
    CGPathMoveToPoint(pathToDraw, NULL, lineCutFirstPoint.x,lineCutFirstPoint.y);
    CGPathAddLineToPoint(pathToDraw, NULL, lineCutSecondPoint.x, lineCutSecondPoint.y);
    lineCut.path = pathToDraw;
    lineCut.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lineCutFirstPoint toPoint:lineCutSecondPoint];
    lineCut.physicsBody.categoryBitMask = lined;
    [self checkCollisions];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [lineCut removeFromParent];
    CGPathRelease(pathToDraw);
    bool ch = [self checkObjectPosition];
    NSLog(@"Check orientation: %d",ch);
}

-(void)update:(CFTimeInterval)dt {
    /* Called before each frame is rendered */
    
    static int maxSpeed = 330;
    
    for(int i=0;i<numberOfObjects;i++){
        SKSpriteNode *tempOb = [myObjects objectAtIndex:i];
        float speed = sqrt(tempOb.physicsBody.velocity.dx*tempOb.physicsBody.velocity.dx +
                           tempOb.physicsBody.velocity.dy * tempOb.physicsBody.velocity.dy);
        if (speed < maxSpeed) {
            // NSLog(@"cat speed Changed");
            [tempOb.physicsBody applyForce:CGVectorMake(tempOb.physicsBody.velocity.dx/2, tempOb.physicsBody.velocity.dy/2)];
            tempOb.physicsBody.linearDamping = 0.0f;
        } else {
            tempOb.physicsBody.linearDamping = 0.5f;
        }
        
    }
}


- (void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody, *secondBody;
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
}


/*
 *
 * checkObjectPosition Function checks whether objects on the screen are on one side of the linecut or both side
 * Parameter: Nothing
 * Return: 0 if points are on the both side of the linecut
 *         1 if points are on the one side of the line
 */
- (bool)checkObjectPosition{
    
    float tempArray[numberOfObjects];
    int flag=0;
    for(int i=0;i<numberOfObjects;i++){
        SKSpriteNode *tempOb = [myObjects objectAtIndex:i];
        CGPoint x1 = tempOb.position;
        float ch = ((lineCutSecondPoint.x - lineCutFirstPoint.x) * (x1.y - lineCutFirstPoint.y)) - ((lineCutSecondPoint.y-lineCutFirstPoint.y)*(x1.x-lineCutFirstPoint.x));
        tempArray[i] = ch;
    }
    if(tempArray[0]<0){
        flag=0;
    }else{
        flag=1;
    }
    for(int i=0;i<numberOfObjects;i++){
        if(tempArray[i]<0 && flag==0){
            flag=0;
        }else if(tempArray[i]>0 && flag==1){
            flag=1;
        }else{
            return false;
        }
    }
    
    return true;
}


- (void)checkCollisions{
    for(int i=0;i<numberOfObjects;i++){
        SKSpriteNode *tempOb = [myObjects objectAtIndex:i];
        [self enumerateChildNodesWithName:[NSString stringWithFormat:@"cat%d",i]
                               usingBlock:^(SKNode *node, BOOL *stop){
                                   if (CGRectIntersectsRect(tempOb.frame, lineCut.frame)) {
                                       //[cat removeFromParent];
                                       NSLog(@"CAT%d AND LINE COLLIDE",i);
                                   }
                               }];
        
        
    }
}

/*
 *
 * Function spawnObjects generates random moving obejcts
 * Parameters: Number of object
 * Return: Nothing
 *
 */
- (void)spawnObjects:(int)num{
    
    numberOfObjects = num;
    for(int i=0;i<numberOfObjects;i++){
        SKSpriteNode *ob = [[SKSpriteNode alloc]init];
        
        ob =[SKSpriteNode spriteNodeWithImageNamed:@"cat"];
        ob.name = [NSString stringWithFormat:@"cat%d",i];
        ob.physicsBody.categoryBitMask = catd;
        ob.physicsBody.contactTestBitMask = lined;
        ob.physicsBody.collisionBitMask = lined;
        
        
        CGSize obSize = CGSizeMake(ob.size.height,ob.size.width);
        
        ob.position = CGPointMake(100 + (i*30), 100 + (i*30));
        
        ob.physicsBody.friction =0.0f;
        ob.physicsBody.linearDamping = 0.0f;
        ob.physicsBody.allowsRotation= YES;
        
        ob.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:obSize];
        [ob.physicsBody setRestitution:1.0f];
        [ob.physicsBody setVelocity:CGVectorMake((arc4random() % 200),arc4random() % 100)];
        [ob.physicsBody applyImpulse:CGVectorMake((arc4random() % 100),arc4random() % 100)];
        [myObjects addObject:ob];
        [self addChild:ob];
    }
}

@end
