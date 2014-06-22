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

/*!
 Scoring points
 */
@property (assign, nonatomic) NSUInteger remainingMovesCount;
@property (assign, nonatomic) NSUInteger score;

/*!
 Storyboard
 */
@property (weak, nonatomic) IBOutlet UILabel *targetScoreHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetScoreValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesValuesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreValueLabel;

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
    self.level = [[EVLevel alloc] initWithFile:@"Levels/Level_1"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    // Create and set the swipe/swap handler block method:
    id block = ^(EVSwap *swap)
    {
        BOOL possibleSwap = [self.level isPossibleSwap:swap];
        if (possibleSwap)
        {
            [self.level performSwap:swap];
        }
        self.view.userInteractionEnabled = NO;
        [self.scene animateSwap:swap
                 isPossibleSwap:possibleSwap
                     completion:^
         {
             if (possibleSwap)
             {
                 [self handleMatches];
             }
             else
             {
                 self.view.userInteractionEnabled = YES;
             }
         }];
    };
    self.scene.swipeHandler = block;
    
    // Present the scene:
    [skView presentScene:self.scene];
    
    // Start the game:
    [self beginGame];
}


#pragma mark - Game methods

-(void)beginGame
{
    // Initialize the scores:
    self.remainingMovesCount = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    // Create the starting collection of friends:
    [self shuffle];
}

-(void)shuffle
{
    NSSet *newFriends = [self.level shuffle];
    [self.scene addSpritesForFriends:newFriends];
}

-(void)handleMatches
{
    NSSet *chains = [self.level removeMatches];

    // We are done when there aren't any chains left to handle:
    if (!chains || !chains.count)
    {
        [self beginNextTurn];
        return;                     /* RETURN when no chains left */
    }
    
    // We have chains, so add their scores to the total score:
    for (EVChain *chain in chains)
    {
        self.score += chain.score;
    }
    
    // There are chains of matching friends that we need to take care of:
    [self.scene animateMatchedFriends:chains
                           completion:^
     {
         [self updateLabels];
         
         NSArray *columnsToFill = [self.level fillHoles];
         [self.scene animateFallingFriends:columnsToFill completion:^
         {
             NSArray *columnsToTopUp = [self.level topUpFriends];
             [self.scene animateNewFriends:columnsToTopUp completion:^
             {
                 // Call this method again to take care of any new chains that
                 // may have formed from the falling and new friends:
                 [self handleMatches];
             }];
         }];
     }];
}

-(void)beginNextTurn
{
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - Scoring

-(void)updateLabels
{
    self.targetScoreValueLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.level.targetScore];
    self.movesValuesLabel.text      = [NSString stringWithFormat:@"%lu", (unsigned long)self.level.maximumMoves];
    self.scoreValueLabel.text       = [NSString stringWithFormat:@"%lu", (unsigned long)self.score];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else
    {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
