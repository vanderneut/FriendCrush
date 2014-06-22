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

/*!
 Animates chains of matching friends, to remove them off the grid.
 */
-(void)animateMatchedFriends:(NSSet *)chains
                  completion:(dispatch_block_t)completion;

/*!
 Animates friend sprites down to show how empty holes in the level are filled 
 with falling friends.
 */
-(void)animateFallingFriends:(NSArray *)columns
                  completion:(dispatch_block_t)completion;

/*!
 Animates sprites for the new sprites that drop into the level to fill the gaps 
 left behind at the top of the columns by the friends that fell into the empty
 tiles left behind by the chains of matched friends that have disappeared from
 the board.
 */
-(void)animateNewFriends:(NSArray *)columns
              completion:(dispatch_block_t)completion;

-(void)animateLevelStart;

-(void)animateLevelEnd;

-(void)removeAllFriendSprites;

@end
