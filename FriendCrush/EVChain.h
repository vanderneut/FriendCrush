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

/*!
 The set of friend objects that form this chain.
 */
@property (strong, nonatomic, readonly) NSArray *friends;

/*!
 Indicates whether this is a horizontal or vertical chain.
 */
@property (assign, nonatomic) EVChainType chainType;

/*!
 Points score associated with this chain.
 */
@property (assign, nonatomic) NSUInteger score;

-(void)addFriend:(EVFriend *)friend;

@end
