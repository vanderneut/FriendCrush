//
//  EVLevel.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVLevel.h"

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
    return [self createInitialFriends];
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
                NSUInteger friendType = arc4random_uniform(NumFriendTypes) + 1;
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

@end
