//
//  EVLevel.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVLevel.h"

@interface EVLevel()

@property (strong, nonatomic) NSSet *possibleSwaps;

@end

@implementation EVLevel

/*!
 Specifies friends population: who they are, and where they are.
 */
EVFriend *_friends[NumColumns][NumRows];

-(NSString *)friendsToString
{
    NSMutableString *string = [NSMutableString stringWithString:@"\n_friends:"];
    for (NSInteger column = 0; column < NumColumns; column++)
    {
        for (NSInteger row = 0; row < NumRows; row++)
        {
            [string appendString:[NSString stringWithFormat:@"\n  [%d][%d] >> %@", column, row, _friends[column][row]]];
        }
    }
    return string;
}

/*!
 Specifies level map: 1 for locations that can hold a friend, 0 for locations 
 where no friend can go.
 */
EVTile *_tiles[NumColumns][NumRows];

-(EVFriend *)friendAtColumn:(NSInteger)column andRow:(NSInteger)row
{
    // RW: "Notice the use of NSAssert1() to verify that the specified column
    // and row numbers are within the valid range of 0-8. This is important when
    // using C arrays because, unlike NSArrays, they don’t check that the index
    // you specify is within bounds. Array indexing bugs can make a big mess of
    // things and they are hard to find, so always protect C array access with
    // an NSAssert!
    NSAssert1(0 <= column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(0 <= row    < NumRows,    @"Invalid row   : %ld", (long)row);
    
    return _friends[column][row];
}

#pragma mark - Creation methods:

/*!
 Initialize the level with the data from a Level JSON file.
 */
-(instancetype)initWithFile:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        NSDictionary *dictionary = [self loadJSON:fileName];
        
        // Loop through the rows of the level:
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop)
        {
            // Loop through the columns in the current row:
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop)
            {
                // NOTE: In Sprite Kit the origin (0, 0) of the coordinates system
                // is at the bottom left of the screen, so read file upside down:
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object:
                if (value.integerValue == 1)
                {
                    _tiles[column][tileRow] = [[EVTile alloc] init];
                }
            }];
        }];
    }
    return self;
}

/*!
 Get the tile at a given position.
 */
-(EVTile *)tileAtColumn:(NSInteger)column andRow:(NSInteger)row
{
    NSAssert1(0 <= column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(0 <= row < NumRows,       @"Invalid row: %ld",    (long)row);
    
    return _tiles[column][row];     /* RETURN tile when found, nil otherwise */
}

/*!
 Generate a random population of the level with friends, in such a way that
 there is at least one swap possible.
 */
-(NSSet *)shuffle
{
    NSSet *set;
    do
    {
        set = [self createInitialFriends];
        [self detectPossibleSwaps];
        NSLog(@"Possible swaps: %@", self.possibleSwaps);
    }
    while (!self.possibleSwaps.count);
    
    return set;
}

/*!
 Generate a random population of the level with friends, in such a way that we
 don't end up with any friend-chains right from the get-go.
 */
-(NSSet *)createInitialFriends
{
    NSMutableSet *set = [NSMutableSet set];
    
    // Loop through the 9x9 grid and create a Friend of random type in each cell:
    for (NSInteger row = 0; row < NumRows; row++)
    {
        for (NSInteger column = 0; column < NumColumns; column++)
        {
            if ([self tileAtColumn:column andRow:row])
            {
                NSUInteger friendType;
                do
                {
                    // Generate random friend type:
                    friendType = arc4random_uniform(NumFriendTypes) + 1;
                }
                while (   // Keep doing it if friendType were to create row or column of 3:
                       (column >= 2 &&
                        _friends[column - 1][row].friendType == friendType &&
                        _friends[column - 2][row].friendType == friendType)
                       ||
                       (row >= 2 &&
                        _friends[column][row - 1].friendType == friendType &&
                        _friends[column][row - 2].friendType == friendType)
                       );
                
                EVFriend *friend = [self createFriendAtColumn:column
                                                       andRow:row
                                                     withType:friendType];
                [set addObject:friend];
            }
        }
    }
    
    NSLog(@"Created friends: %@", set);
    return set;
}

-(EVFriend *)createFriendAtColumn:(NSInteger)column
                           andRow:(NSInteger)row
                         withType:(NSInteger)friendType
{
    EVFriend *friend  = [[EVFriend alloc] init];
    friend.friendType = friendType;
    friend.column     = column;
    friend.row        = row;
    _friends[column][row] = friend;
    
    return friend;
}


#pragma mark - Swap validity

-(void)detectPossibleSwaps
{
    NSMutableSet *set = [NSMutableSet set];
    
    // For each friend in the level, test whether we have a valid swap with
    // another friend on the right, or a friend above.
    
    for (NSInteger row = 0; row < NumRows; row++)
    {
        for (NSInteger column = 0; column < NumColumns; column++)
        {
            EVFriend *friend = _friends[column][row];
            if (friend)
            {
                // Can we swap this friend with friend on the RIGHT?
                
                NSLog(@"---------------------------------------------------------\ndetectPossibleSwaps for %@", friend);
                
                if (column < NumColumns - 1)
                {
                    EVFriend *friendOnRight = _friends[column + 1][row];
                    if (friendOnRight)
                    {
                        NSLog(@"detectPossibleSwaps for %@ has friend on right: %@", friend, friendOnRight);

                        // Swap them:
                        _friends[column][row] = friendOnRight;
                        _friends[column + 1][row] = friend;
                        
                        // Does that swap create a chain?
                        if ([self hasChainAtColumn:column andRow:row] ||
                            [self hasChainAtColumn:(column + 1) andRow:row])
                        {
                            // Found valid swap, so add it to the set of possible swaps:
                            EVSwap *swap = [[EVSwap alloc] init];
                            swap.friendA = friend;
                            swap.friendB = friendOnRight;
                            NSLog(@"detectPossibleSwaps FOUND VALID SWAP with friend on RIGHT: %@", swap);
                            [set addObject:swap];
                        }
                        
                        // Swap them back now:
                        _friends[column][row] = friend;
                        _friends[column + 1][row] = friendOnRight;
                    }
                }
                
                // Can we swap this friend with friend on row ABOVE?
                
                if (row < NumRows - 1)
                {
                    EVFriend *friendAbove = _friends[column][row + 1];
                    if (friendAbove)
                    {
                        NSLog(@"detectPossibleSwaps for %@ has friend above: %@", friend, friendAbove);
                        
                        // Swap them:
                        _friends[column][row] = friendAbove;
                        _friends[column][row + 1] = friend;
                        
                        // Does that swap create a chain?
                        if ([self hasChainAtColumn:column andRow:row] ||
                            [self hasChainAtColumn:column andRow:(row + 1)])
                        {
                            // Found valid swap, so add it to the set of possible swaps:
                            EVSwap *swap = [[EVSwap alloc] init];
                            swap.friendA = friend;
                            swap.friendB = friendAbove;
                            NSLog(@"detectPossibleSwaps FOUND VALID SWAP with friend ABOVE: %@", swap);
                            [set addObject:swap];
                        }
                        
                        // Swap them back now:
                        _friends[column][row] = friend;
                        _friends[column][row + 1] = friendAbove;
                    }
                }
            }
        }
    }
    
    self.possibleSwaps = set;
}

/*!
 Check whether for a friend at a specified location there is a chain of the 
 same friend type of at least 3 friends long.
 */
-(BOOL)hasChainAtColumn:(NSInteger)column andRow:(NSInteger)row
{
    NSUInteger friendType = _friends[column][row].friendType;
    
    NSUInteger chainLengthHorizontal = 1;
    
    // Calculate chain length to the left:
    for (NSInteger i = column - 1;                  // start on left of current friend
         
         i >= 0 &&                                  // while not reached left edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend type
         
         i--,                                       // move one column to the left...
         chainLengthHorizontal++)                   // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    NSLog(@"\thasChainAtColumn:%d andRow:%d -> chainLengthHorizontal left:%d", column, row, chainLengthHorizontal);

    // Calculate chain length to the right:
    for (NSInteger i = column + 1;                  // start on right of current friend
         
         i < NumColumns &&                          // while not reached right edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend type
         
         i++,                                       // move one column to the right...
         chainLengthHorizontal++)                   // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    NSLog(@"\thasChainAtColumn:%d andRow:%d -> chainLengthHorizontal total:%d", column, row, chainLengthHorizontal);
    
    // If left and right combined horizontal length is at least 3, then return YES:
    if (chainLengthHorizontal >= 3) return YES;     /* RETURN YES when chain found */

    NSUInteger chainLengthVertical = 1;

    // Calcualate chain length downward:
    for (NSInteger i = row - 1;                     // start on row below current friend
         
         i >= 0 &&                                  // while not reached bottom edge yet, and...
         _friends[column][i].friendType == friendType; // ...still same friend
         
         i--,                                       // move one row down...
         chainLengthVertical++)                     // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    NSLog(@"\thasChainAtColumn:%d andRow:%d -> chainLengthVertical down:%d", column, row, chainLengthVertical);

    // Calculate chain length upward:
    for (NSInteger i = row + 1;                     // start on row above current friend
         
         i < NumRows &&                             // while not reached top edge yet, and...
         _friends[column][i].friendType == friendType; // ...still same friend
         
         i++,                                       // move one row up...
         chainLengthVertical++)                     // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    NSLog(@"\thasChainAtColumn:%d andRow:%d -> chainLengthVertical total:%d", column, row, chainLengthVertical);
    
    // If up and downward combined vertical length is at least 3, then return YES:
    return (chainLengthVertical >= 3);              /* RETURN YES when chain found, NO otherwise */
}


#pragma mark - JSON level file loading:

-(NSDictionary *)loadJSON:(NSString *)fileName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    if (!path)
    {
        NSLog(@"ERROR: Could not find level file: %@", fileName);
        return nil;         /* RETURN nil when file not found */
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (!data)
    {
        NSLog(@"ERROR: Could not load level file: %@, error: %@", fileName, error);
        return nil;         /* RETURN nil file unreadable */
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"ERROR: Level file %@ is not valid JSON. Error: %@", fileName, error);
        return nil;         /* RETURN nil when file does not contain valid JSON */
    }
    
    return dictionary;
}

#pragma mark - Animation:

-(void)performSwap:(EVSwap *)swap
{
    // Makes the swap in the data model
    
    NSInteger columnA = swap.friendA.column;
    NSInteger rowA    = swap.friendA.row;
    NSInteger columnB = swap.friendB.column;
    NSInteger rowB    = swap.friendB.row;
    
    _friends[columnA][rowA] = swap.friendB;
    swap.friendB.column = columnA;
    swap.friendB.row    = rowA;
    
    _friends[columnB][rowB] = swap.friendA;
    swap.friendA.column = columnB;
    swap.friendA.row    = rowB;
}

#pragma mark - Swap validation:

-(BOOL)isPossibleSwap:(EVSwap *)swap
{
    return [self.possibleSwaps containsObject:swap];
}


#pragma mark - Matches/chains

-(NSSet *)removeMatches
{
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains   = [self detectVerticalMatches];
    
    // Any friends forming chains can be removed from the board:
    [self removeFriends:horizontalChains];
    [self removeFriends:verticalChains];
    
    // Return the combined set of horizontal and vertical chains:
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

/*!
 To detect horizontal matches, go through the whole grid starting at the bottom
 left, looking at each friend. A friend starts a horizontal chain when it has at 
 least two of the same friends directly to the right of it.
 */
-(NSSet *)detectHorizontalMatches
{
    // Create a new set to hold any horizontal chains:
    NSMutableSet *set = [NSMutableSet set];
    
    // Loop through rows and columns. We can skip the rightmost two columns, since
    // there are not enough friends on the right of those to make new chains.
    for (NSInteger row = 0; row < NumRows; row++)
    {
        for (NSInteger column = 0; column < NumColumns - 2; /* no increment here - done inside loop instead */)
        {
            BOOL thisFriendIsStartOfChain = NO;
            if (_friends[column][row])      // skip over gaps in the level map
            {
                NSInteger matchType = _friends[column][row].friendType;
                
                // Check whether at least next two on right are of same type:
                if (_friends[column + 1][row].friendType == matchType &&
                    _friends[column + 2][row].friendType == matchType)
                {
                    // Found chain of 3 or more. Create chain object holding the right length:
                    thisFriendIsStartOfChain = YES;
                    EVChain *chain = [[EVChain alloc] init];
                    chain.chainType = EVChainTypeHorizontal;
                    do
                    {
                        [chain addFriend:_friends[column][row]];
                        column++;
                    }
                    while (column < NumColumns && _friends[column][row].friendType == matchType);
                    
                    // Add this chain to the set:
                    [set addObject:chain];
                }
            }
            
            // If no chain for this friend, go to next column. When chain for
            // this friend, then column index already incremented above.
            if (!thisFriendIsStartOfChain)
            {
                column++;
            }
        }
    }
    
    return set;
}


/*!
 To detect vertical matches, go through the whole grid starting at the bottom
 left, looking at each friend. A friend starts a vertical chain when it has at 
 least two of the same friends directly above it.
 */
-(NSSet *)detectVerticalMatches
{
    // Create a new set to hold any vertical chains:
    NSMutableSet *set = [NSMutableSet set];
    
    // Loop through columns and rows. We can skip the topmost two rows, since
    // there are not enough friends above those to make new chains.
    for (NSInteger column = 0; column < NumColumns; column++)
    {
        for (NSInteger row = 0; row < NumRows - 2;  /* no increment here - done inside loop instead */)
        {
            BOOL thisFriendIsStartOfChain = NO;
            if (_friends[column][row])      // skip over gaps in the level map
            {
                NSInteger matchType = _friends[column][row].friendType;
                
                // Check whether at least next two above are of same type:
                if (_friends[column][row + 1].friendType == matchType &&
                    _friends[column][row + 2].friendType == matchType)
                {
                    // Found chain of 3 or more. Create chain object holding the right length:
                    thisFriendIsStartOfChain = YES;
                    EVChain *chain = [[EVChain alloc] init];
                    chain.chainType = EVChainTypeHorizontal;
                    do
                    {
                        [chain addFriend:_friends[column][row]];
                        row++;
                    }
                    while (row < NumRows && _friends[column][row].friendType == matchType);
                    
                    // Add this chain to the set:
                    [set addObject:chain];
                }
            }
            
            // If no chain for this friend, go to next row. When chain for
            // this friend, then row index already incremented above.
            if (!thisFriendIsStartOfChain)
            {
                row++;
            }
        }
    }
    
    return set;
}

-(void)removeFriends:(NSSet *)chains
{
    for (EVChain *chain in chains)
    {
        for (EVFriend *friend in chain.friends)
        {
            _friends[friend.column][friend.row] = nil;
        }
    }
}

-(NSArray *)fillHoles
{
    NSMutableArray *columns = [NSMutableArray array];
    
    // Loop through the rows, from top to bottom:
    for (NSInteger column = 0; column < NumColumns; column++)
    {
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++)
        {
            // The _tiles array describes the shape of this level, so look at
            // that to see if there is a tile. If tile without friend, then that
            // is an empty tile that needs to be filled:
            if (_tiles[column][row] && !_friends[column][row])
            {
                // Empty tile. Scan upward to find the friend that sits directly
                // above the hole. The hole may be bigger than one tile, and it
                // may span holes in the grid shape as well.
                for (NSInteger rowUp = row +1; rowUp < NumRows; rowUp++)
                {
                    EVFriend *friend = _friends[column][rowUp];
                    if (friend)
                    {
                        // Found friend higher up. Move it down to fill the hole.
                        _friends[column][rowUp] = nil;
                        _friends[column][row] = friend;
                        friend.row = row;
                        
                        // Add this friend to the array. Start of array is lowest in column.
                        if (!array)
                        {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:friend];
                        
                        // We've found the first friend up, so stop scanning further up:
                        break;              /* BREAK */
                    }
                }
            }
        }
    }
    
    return columns;     /* RETURN array with all friends moved down, organized by column */
}

-(NSArray *)topUpFriends
{
    NSMutableArray *columns = [NSMutableArray array];
    NSUInteger friendType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++)
    {
        NSMutableArray *array;
        
        // Starting at top, go down column till we find a friend:
        for (NSInteger row = NumRows - 1; row >= 0 && !_friends[column][row]; row--)
        {
            // Only create friend when there is a tile, when there is not a gap in the level:
            if (_tiles[column][row])
            {
                // Pick random new friend type:
                friendType = arc4random_uniform(NumFriendTypes) + 1;
                
//                // Create random new friend that's different from last one:
//                NSUInteger newFriendType;
//                do
//                {
//                    newFriendType = arc4random_uniform(NumFriendTypes) + 1;
//                }
//                while (newFriendType == friendType);
//                friendType = newFriendType;

                // Create the new friend with the selected type:
                EVFriend *friend = [self createFriendAtColumn:column andRow:row withType:friendType];
                
                // Add this friend to the array (create array first if necessary):
                if (!array)
                {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:friend];
            }
        }
    }
    
    return columns;     /* RETURN the new friends, organized by column */
}

@end
