//
//  EVLevel.h
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVFriend.h"
#import "EVTile.h"
#import "EVSwap.h"
#import "EVChain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface EVLevel : NSObject

-(instancetype)initWithFile:(NSString *)fileName;

-(NSSet *)shuffle;

-(EVFriend *)friendAtColumn:(NSInteger)column
                     andRow:(NSInteger)row;

-(EVTile *)tileAtColumn:(NSInteger)column
                 andRow:(NSInteger)row;

-(void)performSwap:(EVSwap *)swap;

-(BOOL)isPossibleSwap:(EVSwap *)swap;

/*!
 Given the current set of friends and their positions in the level, now generate
 a complete mapping of all the swaps that are valid swaps. Valid swaps are those
 that lead to chains of at least three of the same friends in a row or column.
 */
-(void)detectPossibleSwaps;

-(NSSet *)removeMatches;

/*!
 Convenience method for getting a descriptive string of the _friends array.
 */
-(NSString *)friendsToString;

/*!
 Detects where there are empty tiles and shifts any friends down to fill those
 tiles. It starts at the bottom and scans upwards. If it finds a square that 
 should have a friend but doens't, then it finds the nearest friend above it and
 moves this friend to the empty tile.
 */
-(NSArray *)fillHoles;

/*!
 Add new friends to fill gaps left behind by falling friends. Scans each column
 from the top down, until it fiends a friend. Any empty tiles above that friend
 will be filled with new friends.
 */
-(NSArray *)topUpFriends;

@end
