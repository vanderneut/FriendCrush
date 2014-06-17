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

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface EVLevel : NSObject

-(NSSet *)shuffle;

-(EVFriend *)friendAtColumn:(NSInteger)column
                     andRow:(NSInteger)row;

-(instancetype)initWithFile:(NSString *)fileName;

-(EVTile *)tileAtColumn:(NSInteger)column
                 andRow:(NSInteger)row;

-(void)performSwap:(EVSwap *)swap;

-(BOOL)isPossibleSwap:(EVSwap *)swap;

@end
