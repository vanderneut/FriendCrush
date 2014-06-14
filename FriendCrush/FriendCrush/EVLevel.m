//
//  EVLevel.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVLevel.h"

@implementation EVLevel

EVFriend *_friends[NumColumns][NumRows];

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
            NSUInteger friendType = arc4random_uniform(NumFriendTypes) + 1;
            EVFriend *friend = [self createFriendAtColumn:column
                                                   andRow:row
                                                 withType:friendType];
            [set addObject:friend];
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

@end
