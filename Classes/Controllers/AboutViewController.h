//
//  AboutViewController.h
//  Facemash
//
//  Created by Peter Shih on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UINavigationItem *_navBarItem;
  IBOutlet UITableView *_tableView;
  NSString *_howToPlay;
  NSString *_profile;
  NSString *_statistics;
  NSString *_leaderboards;
  NSString *_privacy;
  NSString *_aboutFacemash;
}

@property (nonatomic, retain) NSString *howToPlay;
@property (nonatomic, retain) NSString *profile;
@property (nonatomic, retain) NSString *statistics;
@property (nonatomic, retain) NSString *leaderboards;
@property (nonatomic, retain) NSString *privacy;
@property (nonatomic, retain) NSString *aboutFacemash;

@end
