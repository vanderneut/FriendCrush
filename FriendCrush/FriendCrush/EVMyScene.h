//
//  EVMyScene.h
//  FriendCrush
//
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

@import SpriteKit;

@class EVLevel;
@class EVSwap;

@interface EVMyScene : SKScene

@property (strong, nonatomic) EVLevel *level;

/*!
 It’s the scene’s job to handle touches. If it recognizes that the user made a 
 swipe, it will call this swipe handler block. This is how it communicates back 
 to the EVViewController that a swap needs to take place.
 
 NOTE: alternative is to use delegates (which I like better!)
 */
@property (copy, nonatomic) void (^swipeHandler)(EVSwap *swap);

-(void)addSpritesForFriends:(NSSet *)friends;

-(void)addTiles;

-(void)animateSwap:(EVSwap *)swap
    isPossibleSwap:(BOOL)possibleSwap
        completion:(dispatch_block_t)completion;

@end
