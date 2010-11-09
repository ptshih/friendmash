//
//  RankingsViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LauncherViewController;

@interface RankingsViewController : UIViewController {
  LauncherViewController *_launcherViewController;
}

@property (nonatomic, assign) LauncherViewController *launcherViewController;

- (IBAction)dismissRankings;

@end
