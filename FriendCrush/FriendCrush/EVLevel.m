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

-(EVTile *)tileAtColumn:(NSInteger)column andRow:(NSInteger)row
{
    NSAssert1(0 <= column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(0 <= row < NumRows,       @"Invalid row: %ld",    (long)row);
    
    return _tiles[column][row];     /* RETURN tile when found, nil otherwise */
}

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
                
                if (column < NumColumns - 1)
                {
                    EVFriend *friendOnRight = _friends[column + 1][row];
                    if (friendOnRight)
                    {
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

-(BOOL)hasChainAtColumn:(NSInteger)column andRow:(NSInteger)row
{
    NSUInteger friendType = _friends[column][row].friendType;
    
    NSUInteger chainLength = 1;
    
    // Calculate chain length to the left:
    for (NSInteger i = column - 1;                  // start on left of current friend
         
         i >= 0 &&                                  // while not reached left edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend type
         
         i--,                                       // move one column to the left...
         chainLength++)                             // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    if (chainLength >= 3) return YES;               /* RETURN YES when chain found */
    
    // Calculate chain length to the right:
    for (NSInteger i = column + 1;                  // start on right of current friend
         
         i < NumColumns &&                          // while not reached right edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend type
         
         i++,                                       // move one column to the right...
         chainLength++)                             // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    if (chainLength >= 3) return YES;               /* RETURN YES when chain found */

    // Calcualate chain length downward:
    for (NSInteger i = row - 1;                     // start on row below current friend
         
         i >= 0 &&                                  // while not reached bottom edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend
         
         i--,                                       // move one row down...
         chainLength++)                             // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    if (chainLength >= 3) return YES;               /* RETURN YES when chain found */

    // Calculate chain length upward:
    for (NSInteger i = row + 1;                     // start on row above current friend
         
         i < NumRows &&                             // while not reached top edge yet, and...
         _friends[i][row].friendType == friendType; // ...still same friend
         
         i++,                                       // move one row up...
         chainLength++)                             // ...and increment chain length
        ;                                           // (nothing left to do in loop)
    
    return (chainLength >= 3);                      /* RETURN YES when chain found, NO otherwise */
}

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

@end
