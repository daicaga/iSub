//
//  CustomUITableViewController.m
//  iSub
//
//  Created by Benjamin Baron on 10/9/13.
//  Copyright (c) 2013 Ben Baron. All rights reserved.
//

#import "CustomUITableViewController.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "ServerListViewController.h"

@implementation CustomUITableViewController

#pragma mark - Lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jukeboxToggled) name:ISMSNotification_JukeboxEnabled object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jukeboxToggled) name:ISMSNotification_JukeboxDisabled object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupLeftBarButton) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateBackgroundColor];
    
    [self setupLeftBarButton];
    [self setupRightBarButton];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ISMSNotification_JukeboxEnabled object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ISMSNotification_JukeboxDisabled object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - UI -

- (void)updateBackgroundColor
{
    self.view.backgroundColor = settingsS.isJukeboxEnabled ? viewObjectsS.jukeboxColor : viewObjectsS.windowColor;
}

- (void)jukeboxToggled
{
    [self updateBackgroundColor];
}

- (void)setupLeftBarButton
{
    BOOL isRootViewController = self.navigationController.viewControllers[0] == self;
    BOOL isInsideMoreTab = appDelegateS.mainTabBarController.selectedIndex == 4;
    
    UIBarButtonItem *leftBarButtonItem = nil;
    
    if (isRootViewController)
    {
        if (settingsS.isOfflineMode)
        {
            leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"]
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(settingsAction:)];
        }
        else if (appDelegateS.referringAppUrl && !isInsideMoreTab)
        {
            // Add a back button to return to the reffering app if there is one and we're the root controller
            leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:appDelegateS
                                                                action:@selector(backToReferringApp)];
        }
    }
    
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)setupRightBarButton
{
    UIBarButtonItem *rightBarButtonItem = nil;
    
    if(musicS.showPlayerIcon)
    {
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"now-playing.png"]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(nowPlayingAction:)];
    }
    
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

#pragma mark - Actions -

- (void)settingsAction:(id)sender
{
    ServerListViewController *serverListViewController = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil];
    serverListViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:serverListViewController animated:YES];
}

- (void)nowPlayingAction:(id)sender
{
    iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
    streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:streamingPlayerViewController animated:YES];
}

@end
