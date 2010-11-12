//
//  RankingsViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageCache.h"

@class ASINetworkQueue;
@class LauncherViewController;

@interface RankingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ImageCacheDelegate> {
  IBOutlet UITableView *_tableView;
  LauncherViewController *_launcherViewController;
  NSArray *_rankingsArray;
  ImageCache *_imageCache;
  ASINetworkQueue *_networkQueue;
  NSString *_selectedGender;
  NSInteger _selectedMode;
}

@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (nonatomic, retain) NSArray *rankingsArray;
@property (nonatomic, retain) ImageCache *imageCache;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, retain) NSString *selectedGender;

- (void)loadImagesForOnscreenRows;
- (void)getTopRankingsForGender:(NSString *)gender andMode:(NSInteger)mode;
- (IBAction)selectMode:(UISegmentedControl *)segmentedControl;
- (IBAction)dismissRankings;

@end
