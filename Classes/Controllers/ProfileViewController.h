//
//  ProfileViewController.h
//  Friendmash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProfileDelegate <NSObject>
@optional
- (void)shouldPerformLogout;
@end

@class ASIHTTPRequest;
@class LauncherViewController;

@interface ProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UINavigationItem *_navBarItem;
  IBOutlet UITableView *_tableView;
  LauncherViewController *_launcherViewController;
  ASIHTTPRequest *_profileRequest;
  NSDictionary *_profileDict;
  NSString *_profileId;
  id <ProfileDelegate> delegate;
}

@property (nonatomic, retain) UINavigationItem *navBarItem;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (nonatomic, retain) ASIHTTPRequest *profileRequest;
@property (nonatomic, retain) NSDictionary *profileDict;
@property (nonatomic, retain) NSString *profileId;
@property (nonatomic, assign) id <ProfileDelegate> delegate;

- (void)done;

- (NSString *)getRankForVotes:(NSInteger)votes;

@end
