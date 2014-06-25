//
//  EVFriend.h
//  FriendCrush
//
//  Model class, holding the data for one of the friends.
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

@import SpriteKit;

static const NSUInteger NumFriendTypes = 6;

@interface EVFriend : NSObject

@property (assign, nonatomic) NSInteger column;         // horizontal position in 9x9 grid
@property (assign, nonatomic) NSInteger row;            // vertical position in 9x9 grid
@property (assign, nonatomic) NSUInteger friendType;    // identifies which friend it is
@property (strong, nonatomic) SKSpriteNode *sprite;     //

- (NSString *)spriteName;             // TODO: this will have the change when pulling friend profile pics from Fb instead
- (NSString *)highlightedSpriteName;  // TODO: this will have the change when pulling friend profile pics from Fb instead

@end
