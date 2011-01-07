//
//  RankingsViewController.h
//  Friendmash
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

@class ASIHTTPRequest;
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
  ASIHTTPRequest *_rankingsRequest;
  NSInteger _selectedMode;
  NSInteger _gameMode;
}

// IBOutlets
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UITabBar *tabBar;
@property (nonatomic, retain) UITabBarItem *tabBarItemTop;
@property (nonatomic, retain) UITabBarItem *tabBarItemMale;
@property (nonatomic, retain) UITabBarItem *tabBarItemFemale;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UINavigationItem *navItem;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;

@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (nonatomic, retain) NSArray *rankingsArray;
@property (nonatomic, retain) ImageCache *imageCache;
@property (nonatomic, retain) ASIHTTPRequest *rankingsRequest;
@property (nonatomic, assign) NSInteger selectedMode;
@property (nonatomic, assign) NSInteger gameMode;

- (void)loadImagesForOnscreenRows;
- (void)getTopPlayers;
- (void)getTopRankings;
- (IBAction)refreshRankings;
- (IBAction)dismissRankings;

@end
