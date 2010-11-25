//
//  RankingsViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageCache.h"

typedef enum {
  RankingsModeTop = 0,
  RankingsModeMale = 1,
  RankingsModeFemale = 2
} RankingsMode;

@class ASINetworkQueue;
@class LauncherViewController;

@interface RankingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ImageCacheDelegate, UITabBarDelegate> {
  IBOutlet UITableView *_tableView;
  IBOutlet UITabBar *_tabBar;
  IBOutlet UITabBarItem *_tabBarItemTop;
  IBOutlet UITabBarItem *_tabBarItemMale;
  IBOutlet UITabBarItem *_tabBarItemFemale;
  IBOutlet UIView *_loadingView;
  IBOutlet UINavigationItem *_navItem;
  IBOutlet UIBarButtonItem *_refreshButton;
  LauncherViewController *_launcherViewController;
  NSArray *_rankingsArray;
  ImageCache *_imageCache;
  ASINetworkQueue *_networkQueue;
  NSInteger _selectedMode;
  NSInteger _gameMode;
}

@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (nonatomic, retain) NSArray *rankingsArray;
@property (nonatomic, retain) ImageCache *imageCache;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, assign) NSInteger selectedMode;
@property (nonatomic, assign) NSInteger gameMode;

- (void)loadImagesForOnscreenRows;
- (void)getTopPlayers;
- (void)getTopRankings;
- (IBAction)refreshRankings;
- (IBAction)dismissRankings;

@end
