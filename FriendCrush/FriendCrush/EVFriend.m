//
//  EVFriend.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVFriend.h"

@implementation EVFriend

-(NSString *)spriteName
{
    static NSString * const spriteNames[] =
    {
        @"Croissant",
        @"Cupcake",
        @"Danish",
        @"Donut",
        @"Macaroon",
        @"SugarCookie",
    };
    
    // Translate friend type to sprite name:
    return spriteNames[self.friendType - 1];
}

-(NSString *)highlightedSpriteName
{
    static NSString * const highlightedSpriteNames[] =
    {
        @"Croissant-Highlighted",
        @"Cupcake-Highlighted",
        @"Danish-Highlighted",
        @"Donut-Highlighted",
        @"Macaroon-Highlighted",
        @"SugarCookie-Highlighted",
    };
    
    // Translate friend type to highlighted sprite name:
    return highlightedSpriteNames[self.friendType - 1];
    
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"Friend type %ld on square: (%ld, %ld)",
            (long)self.friendType, (long)self.column, (long)self.row];
}

@end
