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
#import "EVFriend.h"

@implementation EVSwap

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.friendA, self.friendB];
}

/*!
 Overwriting isEqual: so we can easily compare swap objects.
 NOTE: when overwriting isEqual, it is crucial to also write our own version of hash method!
 */
-(BOOL)isEqual:(id)object
{
    // Only compare this object against other EVSwap objects:
    if (![object isKindOfClass:[EVSwap class]]) return NO;      /* RETURN NO when other object of different kind */
    
    // Two swaps are equal if they contain the same two friends, but it doesn't
    // matter in which order:
    EVSwap *otherSwap = (EVSwap *)object;
    
    if (otherSwap.friendA == self.friendA && otherSwap.friendB == self.friendB)
    {
        NSLog(@"%@ is equal to %@", self, otherSwap);
        return YES;     /* RETURN YES when same friends in same order */
    }
    
    if (otherSwap.friendB == self.friendA && otherSwap.friendA == self.friendB)
    {
        NSLog(@"%@ is reverse equal to %@", self, otherSwap);
        return YES;     /* RETURN YES when same friends, in reverse order */
    }
    
    NSLog(@"%@ is NOT equal to %@", self, otherSwap);
    return NO;          /* RETURN NO when other swap refers to different friends */
}

/*!
 Our own version of the hash method, because we overwrote isEqual: above.
 If two objects are equal, their hashes must be equal. Combing the two hashes of
 the two friends here with a bitwise XOR to achieve this.
 */
-(NSUInteger)hash
{
    return [self.friendA hash] ^ [self.friendB hash];
}

@end
