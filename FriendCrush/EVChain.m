//
//  EVChain.m
//  FriendCrush
//
//  Created by Erik van der Neut on 20/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVChain.h"

@implementation EVChain
{
    NSMutableArray *_friends;
}

-(void)addFriend:(EVFriend *)friend
{
    if (!_friends)
    {
        _friends = [NSMutableArray array];
    }
    
    [_friends addObject:friend];
}

-(NSArray *)friends
{
    return _friends;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"Chain of type %d for friends %@", self.chainType, _friends];
}

@end
