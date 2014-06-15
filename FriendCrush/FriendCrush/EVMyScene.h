//
//  EVMyScene.h
//  FriendCrush
//
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

@import SpriteKit;

@class EVLevel;

@interface EVMyScene : SKScene

@property (strong, nonatomic) EVLevel *level;

-(void)addSpritesForFriends:(NSSet *)friends;

-(void)addTiles;

@end
