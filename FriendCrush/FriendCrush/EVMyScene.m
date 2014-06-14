//
//  EVMyScene.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVMyScene.h"
#import "EVFriend.h"
#import "EVLevel.h"

static const CGFloat TileWidth  = 32.0;
static const CGFloat TileHeight = 36.0;

@interface EVMyScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *friendsLayer;

@end

@implementation EVMyScene

-(instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        self.gameLayer = [SKNode node];
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth * 0.5 * NumColumns, -TileHeight * 0.5 * NumRows);
        
        self.friendsLayer = [SKNode node];
        self.friendsLayer.position = layerPosition;
        
        [self.gameLayer addChild:self.friendsLayer];
    }
    return self;
}

-(void)addSpritesForFriends:(NSSet *)friends
{
    for (EVFriend *friend in friends)
    {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:friend.spriteName];
        sprite.position = [self getCGPointForColumn:friend.column andRow:friend.row];
        [self.friendsLayer addChild:sprite];
        friend.sprite = sprite;
    }
}

-(CGPoint)getCGPointForColumn:(NSInteger)column andRow:(NSInteger)row
{
    // Return the center point for this friend's sprite:
    return CGPointMake(0.5 * TileWidth  + column * TileWidth,
                       0.5 * TileHeight +    row * TileHeight);
}

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    /* Called when a touch begins */
//    
//    for (UITouch *touch in touches)
//    {
//        CGPoint location = [touch locationInNode:self];
//        
//        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
//        
//        sprite.position = location;
//        
//        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
//        
//        [sprite runAction:[SKAction repeatActionForever:action]];
//        
//        [self addChild:sprite];
//    }
//}
//
//-(void)update:(CFTimeInterval)currentTime
//{
//    /* Called before each frame is rendered */
//}

@end
