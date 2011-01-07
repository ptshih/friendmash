//
//  AboutViewController.h
//  Friendmash
//
//  Created by Peter Shih on 11/13/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UINavigationItem *_navBarItem;
  IBOutlet UITableView *_tableView;
  NSString *_howToPlay;
  NSString *_profile;
  NSString *_leaderboards;
  NSString *_aboutFriendmash;
}

@property (nonatomic, retain) UINavigationItem *navBarItem;
@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, retain) NSString *howToPlay;
@property (nonatomic, retain) NSString *profile;
@property (nonatomic, retain) NSString *leaderboards;
@property (nonatomic, retain) NSString *aboutFriendmash;

@end
