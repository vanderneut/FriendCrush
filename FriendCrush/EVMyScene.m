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
#import "EVSwap.h"

static const CGFloat TileWidth  = 32.0;
static const CGFloat TileHeight = 36.0;

@interface EVMyScene ()

/*!
 Scene view layers
 */
@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *friendsLayer;
@property (strong, nonatomic) SKNode *tilesLayer;

/*!
 Record the column and row numbers of the friend that the player first touched
 when they started the swipe movement.
 */
@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

/*!
 Sprite highlighting 
 */
@property (strong, nonatomic) SKSpriteNode *selectionSprite;

/*!
 Sound FX
 */
@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invalidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingFriendSound;
@property (strong, nonatomic) SKAction *addFriendSound;

/*!
 Grid graphic fine tuning
 */
@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@end

@implementation EVMyScene

-(instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        // Screen background:
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        // Game layer:
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;        // hide gamelayer until animating it into view
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth * 0.5 * NumColumns, -TileHeight * 0.5 * NumRows);
        
        // Layer to hold the tiles background images:
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        // Set up the crop layer:
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        // Set up the mask layer:
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        // Layer to hold the friend images:
        self.friendsLayer = [SKNode node];
        self.friendsLayer.position = layerPosition;
//        [self.cropLayer addChild:self.maskLayer];
        [self.cropLayer addChild:self.friendsLayer];
        
        // Initialize the swipe starting column and row numbers:
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        // Initialize selected sprite:
        self.selectionSprite = [SKSpriteNode node];

        // Preload all the sound effects:
        [self preloadResources];
    }
    
    return self;
}

-(void)preloadResources
{
    // Preload sounds:
    self.swapSound          = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound   = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound         = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingFriendSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addFriendSound     = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    
    // Preload fonts:
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

/*!
 Draw the friend sprites into their view layer.
 */
-(void)addSpritesForFriends:(NSSet *)friends
{
    for (EVFriend *friend in friends)
    {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:friend.spriteName];
        sprite.position = [self getCGPointForColumn:friend.column andRow:friend.row];
        [self.friendsLayer addChild:sprite];
        friend.sprite = sprite;
        
        // Animate the appearance of this friend sprite, so upon shuffle it's less abrupt:
        friend.sprite.alpha = 0.0;
        friend.sprite.xScale = friend.sprite.yScale = 0.0;
        [friend.sprite runAction:[SKAction sequence:@[[SKAction waitForDuration:0.2 withRange:0.4],
                                                      [SKAction group:@[[SKAction fadeInWithDuration:0.2],
                                                                        [SKAction scaleTo:1.0 duration:0.2]]]]]];
//        friend.sprite.alpha = 0.5;
//        [friend.sprite runAction:[SKAction fadeInWithDuration:0.5]];
    }
}

/*!
 In the view, add a background tile to each valid position in the level, so the 
 user can clearly see the layout of this level.
 */
-(void)addTiles
{
    for (NSInteger row = 0; row < NumRows; row++)
    {
        for (NSInteger column = 0; column < NumColumns; column++)
        {
            if ([self.level tileAtColumn:column andRow:row])
            {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaskTile"];
                tileNode.position = [self getCGPointForColumn:column andRow:row];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    for (NSInteger row = 0; row <= NumRows; row++)
    {
        for (NSInteger column = 0; column <= NumColumns; column++)
        {
            // IMPORTANT NOTE:
            // These background tiles are centered on the corners _between_ the
            // tiles. That way, their shape is entirely determined by whether
            // there is a friend at the top left, top right, bottom left or
            // bottom right of their position. Note also that because this is
            // placed at the intersection of friend squares (instead of directly
            // behind them), that the 0,0 origin of the background tiles is
            // offset by -1,-1 compared to the friend coordinates.
            
            // Determine on which corners this tile has a friend next time:
            BOOL topLeft     = (column > 0)          && (row < NumRows) && [self.level tileAtColumn:column - 1 andRow:row];
            BOOL bottomLeft  = (column > 0)          && (row > 0)       && [self.level tileAtColumn:column - 1 andRow:row - 1];
            BOOL topRight    = (column < NumColumns) && (row < NumRows) && [self.level tileAtColumn:column     andRow:row];
            BOOL bottomRight = (column < NumColumns) && (row > 0)       && [self.level tileAtColumn:column     andRow:row - 1];
            
            // The tile background shapes are named 0 to 15, where the numbers
            // correspond to the bitmask created by combining the four booleans:
            NSUInteger tileNumber = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
//            NSLog(@"addTiles >> column %d, row %d >> tileNumber %d from: TL %d, BL %d, TR %d, BR %d", column, row, tileNumber, topLeft, bottomLeft, topRight, bottomRight);
            
            // Not drawn are tiles for bitMask values of 0 (no tiles), 6 and 9 (opposite tiles):
            if (tileNumber && tileNumber != 6 && tileNumber != 9)
            {
                NSString *tileName = [NSString stringWithFormat:@"Tile_%d", tileNumber];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:tileName];
                
                CGPoint tilePosition = [self getCGPointForColumn:column andRow:row];
                tilePosition.x   -= 0.5 * TileWidth;
                tilePosition.y   -= 0.5 * TileHeight;
                tileNode.position = tilePosition;
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

-(CGPoint)getCGPointForColumn:(NSInteger)column andRow:(NSInteger)row
{
    // Return the center point for this friend's sprite:
    return CGPointMake(0.5 * TileWidth  + column * TileWidth,
                       0.5 * TileHeight +    row * TileHeight);
}

-(BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column andRow:(NSInteger *)row
{
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Check whether this is a valid location within the friends layer:
    if (0 <= point.x < NumColumns * TileWidth &&
        0 <= point.y < NumRows * TileHeight)
    {
        // If YES, calculate corresponding row and column numbers:
        *column = point.x / TileWidth;
        *row    = point.y / TileHeight;
        return YES;
    }
    else
    {
        // If NO, calculate corresponding row and column numbers:
        *column = NSNotFound;
        *row    = NSNotFound;
        return NO;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    
    // Convert touch point to friends-layer point:
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.friendsLayer];
    
    // If the touch is inside the 9x9 grid...
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column andRow:&row])
    {
        // ...and touch is on a friend, not an empty square...
        EVFriend *friend = [self.level friendAtColumn:column andRow:row];
        if (friend)
        {
            // ...record the column and row from where the swipe is starting:
            self.swipeFromColumn = column;
            self.swipeFromRow    = row;
            
            [self showSelectionIndicatorForFriend:friend];
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // If not a valid starting column, then either the swipe began outside the
    // the valid area, or the game has already swapped the friends:
    if (self.swipeFromColumn == NSNotFound)
    {
        return;     /* RETURN when don't need to handle (rest) of this swipe */
    }

    // Convert touch point to friends-layer point:
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.friendsLayer];
    
    // If the touch is inside the 9x9 grid...
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column andRow:&row])
    {
        // Figure out swipe direction:
        NSInteger deltaHorizontal = 0, deltaVertical = 0;
        if (column < self.swipeFromColumn)
        {
            deltaHorizontal = -1;   // swipe left
        }
        else if (column > self.swipeFromColumn)
        {
            deltaHorizontal = 1;    // swipe right
        }
        else if (row < self.swipeFromRow)
        {
            deltaVertical = -1;     // swipe down
        }
        else if (row > self.swipeFromRow)
        {
            deltaVertical = 1;      // swipe up
        }
        
        // Only perform the swipe if player swiped out of the old square:
        if (deltaHorizontal || deltaVertical)
        {
            [self trySwapHorizontal:deltaHorizontal orVertical:deltaVertical];
            [self hideSelectionIndicator];
            self.swipeFromColumn = self.swipeFromRow = NSNotFound;      // ignore rest of swipe
        }
    }
}

/*!
 Determine whether a swap is allowed in the specified direction, and if it is, 
 then perform it.
 */
-(void)trySwapHorizontal:(NSInteger)deltaHorizontal orVertical:(NSInteger)deltaVertical
{
    // Calculate location of the friend to swap with:
    NSInteger toColumn = self.swipeFromColumn + deltaHorizontal;
    NSInteger toRow    = self.swipeFromRow    + deltaVertical;
    
    // Don't swap when user swiped across outer edge of 9x9 grid:
    if (toColumn < 0 || toColumn >= NumColumns) return;             /* RETURN */
    if (toRow    < 0 || toRow    >= NumRows)    return;             /* RETURN */
    
    // Don't swap if there is no friend at the swipe destination:
    EVFriend *toFriend = [self.level friendAtColumn:toColumn andRow:toRow];
    if (!toFriend) return;                                          /* RETURN */
    
    // We have two friends to swap:
    EVFriend *fromFriend = [self.level friendAtColumn:self.swipeFromColumn andRow:self.swipeFromRow];
    
    NSLog(@"Swapping %@ with %@...", fromFriend, toFriend);
    
    if (self.swipeHandler)
    {
        EVSwap *swap = [[EVSwap alloc] init];
        swap.friendA = fromFriend;
        swap.friendB = toFriend;
        
        self.swipeHandler(swap);
    }
}

/*!
 Run the view animation to show the swap to the player
 */
-(void)animateSwap:(EVSwap *)swap
    isPossibleSwap:(BOOL)possibleSwap
        completion:(dispatch_block_t)completion
{
    // Place the starting friend on top:
    swap.friendA.sprite.zPosition = 100;
    swap.friendB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.friendB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.friendA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    if (possibleSwap)
    {
        [swap.friendA.sprite runAction:moveA completion:completion];
        [swap.friendB.sprite runAction:moveB];
        [self runAction:self.swapSound];
    }
    else
    {
        [swap.friendA.sprite runAction:[SKAction sequence:@[moveA, moveB]] completion:completion];
        [swap.friendB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
        [self runAction:self.invalidSwapSound];
    }
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.selectionSprite.parent && self.swipeFromColumn != NSNotFound)
    {
        [self hideSelectionIndicator];
    }

    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

/*!
 High-light the friend in the grid that the user is touching.
 */
-(void)showSelectionIndicatorForFriend:(EVFriend *)friend
{
    // If selection indicator still visible, then remove it first:
    if (self.selectionSprite.parent)
    {
        [self.selectionSprite removeFromParent];
    }
    
    NSLog(@"High-lighting %@...", friend);
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[friend highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [friend.sprite addChild:self.selectionSprite];  // make it move with the sprite
    self.selectionSprite.alpha = 1.0;               // make it visible
}

-(void)hideSelectionIndicator
{
    [self.selectionSprite runAction:[SKAction fadeOutWithDuration:0.3]
                         completion:^
     {
         [self.selectionSprite removeFromParent];
     }];
}

-(void)animateMatchedFriends:(NSSet *)chains
                  completion:(dispatch_block_t)completion
{
    const NSTimeInterval AnimationDuration = 0.2;
    
    for (EVChain *chain in chains)
    {
        [self animatePointsScoreForChain:chain];
        
        for (EVFriend *friend in chain.friends)
        {
            // Any friend could be part of two chains (one horizontal and one vertical),
            // but we only want to add one animation to the sprite. This check ensures
            // that we only animate the sprite once:
            if (friend.sprite)
            {
                // Shrink the sprite, and remove it when animation is done:
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:AnimationDuration];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [friend.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                // Unlink sprite from the friend right away now (so we don't trigger additional animations on it):
                friend.sprite = nil;
            }
        }
    }
    
    // Play Match sound effect:
    [self runAction:self.matchSound];
    
    // Continue with the rest of the game after the animations have finished:
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:AnimationDuration],
                                         [SKAction runBlock:completion]]]];
}

-(void)animateFallingFriends:(NSArray *)columns
                  completion:(dispatch_block_t)completion
{
    // Only call the completion block after all animations are complete. The
    // duration of the total animation depends on the number of friends to
    // animate, so this duration will be calculated below.
    __block NSTimeInterval totalAnimationDuration = 0;
    
    for (NSArray *array in columns)
    {
        [array enumerateObjectsUsingBlock:^(EVFriend *friend, NSUInteger idx, BOOL *stop)
        {
            CGPoint newPosition = [self getCGPointForColumn:friend.column andRow:friend.row];
            
            // Animation delay is longer for higher friends, which are later in the array:
            NSTimeInterval delay = 0.05 + 0.10 * idx;
            
            // Animation duration is longer for friends that have to fall faster (0.1 per tile):
            NSTimeInterval duration = ((friend.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            // Ensure that total animation duration covers whatever animation takes the longest:
            totalAnimationDuration = MAX(delay + duration, totalAnimationDuration);
            
            // Perform animation: delay, movement, sound effect:
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseIn;
            [friend.sprite runAction:[SKAction sequence:@[[SKAction waitForDuration:delay],
                                                          [SKAction group:@[moveAction, self.fallingFriendSound]]]]];
        }];
    }
    
    // Allow gameplay to continue once all friends have completed their fall:
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:totalAnimationDuration],
                                         [SKAction runBlock:completion]]]];
}

-(void)animateNewFriends:(NSArray *)columns
              completion:(dispatch_block_t)completion
{
    // Only call the completion block after all animations are complete. The
    // duration of the total animation depends on the number of friends to
    // animate, so this duration will be calculated below.
    __block NSTimeInterval totalAnimationDuration = 0;
    
    for (NSArray *array in columns)
    {
        // New friends always drop in from directly above the top row:
        NSInteger startRow = NumRows; // <- isn't that more straightforward? -- instead of: ((EVFriend *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(EVFriend *friend, NSUInteger idx, BOOL *stop)
         {
             // Set the starting position for the sprite animation - above top row:
             friend.sprite = [SKSpriteNode spriteNodeWithImageNamed:friend.spriteName];
             friend.sprite.position = [self getCGPointForColumn:friend.column andRow:startRow];     // <- NOTE: startRow instead of friend.row here
             [self.friendsLayer addChild:friend.sprite];
             
             // Animation delay is longer for higher friends, which are later in the array:
             NSTimeInterval delay = 0.1 + 0.2 * (array.count - idx - 1);
             
             // Animation duration is longer for friends that have to fall faster (0.1 per tile):
             NSTimeInterval duration = (startRow - friend.row) * 0.1;
             
             // Ensure that total animation duration covers whatever animation takes the longest:
             totalAnimationDuration = MAX(delay + duration, totalAnimationDuration);
             
             // Perform animation: delay, movement, sound effect:
             CGPoint newPosition = [self getCGPointForColumn:friend.column andRow:friend.row];      // <- NOTE: friend.row for the destination
             SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
             moveAction.timingMode = SKActionTimingEaseIn;
             friend.sprite.alpha = 0.0;
             [friend.sprite runAction:[SKAction sequence:@[[SKAction waitForDuration:delay],
                                                           [SKAction group:@[[SKAction fadeInWithDuration:0.05],
                                                                             moveAction,
                                                                             self.fallingFriendSound]]]]];
         }];
    }
    
    // Allow gameplay to continue once all the new friends have appeared and fallen into place:
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:totalAnimationDuration],
                                         [SKAction runBlock:completion]]]];
}

-(void)animatePointsScoreForChain:(EVChain *)chain
{
    // Calculate the mid-point location of this chain:
    EVFriend *firstFriend = [chain.friends firstObject];
    EVFriend *lastFriend  = [chain.friends lastObject];
    
    CGPoint midPoint = CGPointMake(0.5 * (firstFriend.sprite.position.x + lastFriend.sprite.position.x),
                                   0.5 * (firstFriend.sprite.position.y + lastFriend.sprite.position.y) - 8);

    // Add a label for the score that slowly floats up:
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontColor = [SKColor whiteColor];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)chain.score];
    scoreLabel.position = midPoint;
    scoreLabel.zPosition = 300;
    [self.friendsLayer addChild:scoreLabel];
    
    SKAction *moveLabelAction = [SKAction moveBy:CGVectorMake(0, 5) duration:0.6];
    moveLabelAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:moveLabelAction completion:^{
        [scoreLabel removeFromParent];
    }];
}

-(void)animateLevelStart
{
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height)
                               duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

-(void)animateLevelEnd
{
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height)
                               duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

-(void)removeAllFriendSprites
{
    [self.friendsLayer removeAllChildren];
}

@end
