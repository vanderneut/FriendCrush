//
//  EVViewController.m
//  FriendCrush
//
//  Created by Erik van der Neut on 14/06/2014.
//  Copyright (c) 2014 Erik van der Neut. All rights reserved.
//

#import "EVViewController.h"
#import "EVMyScene.h"
#import "EVLevel.h"

@interface EVViewController()

@property (strong, nonatomic) EVLevel *level;
@property (strong, nonatomic) EVMyScene *scene;

@end

@implementation EVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view:
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.multipleTouchEnabled = NO;
    
    // Create and configure the scene:
    self.scene = [EVMyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Load the level:
    self.level = [[EVLevel alloc] init];
    self.scene.level = self.level;
    
    // Present the scene:
    [skView presentScene:self.scene];
    
    // Start the game:
    [self beginGame];
}


#pragma mark - Game methods

-(void)beginGame
{
    [self shuffle];
}

-(void)shuffle
{
    NSSet *newFriends = [self.level shuffle];
    [self.scene addSpritesForFriends:newFriends];
}

#pragma mark - Misc.

- (BOOL)shouldAutorotate
{
    return YES;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
