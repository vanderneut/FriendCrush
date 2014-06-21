//
//  EVChain.h
//  FriendCrush
//
//  Created by Erik van der Neut on 20/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

@class EVFriend;

typedef NS_ENUM(NSUInteger, EVChainType)
{
    EVChainTypeHorizontal,
    EVChainTypeVertical,
};

@interface EVChain : NSObject

@property (strong, nonatomic, readonly) NSArray *friends;
@property (assign, nonatomic) EVChainType chainType;

-(void)addFriend:(EVFriend *)friend;

@end
