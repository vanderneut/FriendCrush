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
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth * 0.5 * NumColumns, -TileHeight * 0.5 * NumRows);
        
        // Layer to hold the tiles background images:
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        // Layer to hold the friend images:
        self.friendsLayer = [SKNode node];
        self.friendsLayer.position = layerPosition;
        [self.gameLayer addChild:self.friendsLayer];
        
        // Initialize the swipe starting column and row numbers:
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
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

-(void)addTiles
{
    for (NSInteger row = 0; row < NumRows; row++)
    {
        for (NSInteger column = 0; column < NumColumns; column++)
        {
            if ([self.level tileAtColumn:column andRow:row])
            {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                tileNode.position = [self getCGPointForColumn:column andRow:row];
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
            
            NSLog(@"Touch detected on friend in column %d and row %d", column, row);
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
            self.swipeFromColumn = self.swipeFromRow = NSNotFound;      // ignore rest of swipe
        }
    }
}

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

-(void)animateSwap:(EVSwap *)swap completion:(dispatch_block_t)completion
{
    // Place the starting friend on top:
    swap.friendA.sprite.zPosition = 100;
    swap.friendB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.friendB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.friendA.sprite runAction:moveA completion:completion];
    
    SKAction *moveB = [SKAction moveTo:swap.friendA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.friendB.sprite runAction:moveB];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

//-(void)update:(CFTimeInterval)currentTime
//{
//    /* Called before each frame is rendered */
//}

@end
