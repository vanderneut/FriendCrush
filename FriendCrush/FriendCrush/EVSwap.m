//
//  EVSwap.m
//  FriendCrush
//
//  Model class with the purpose to describe the swapping of two friends
//
//  Created by Erik van der Neut on 15/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVSwap.h"

@implementation EVSwap

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.friendA, self.friendB];
}

@end
