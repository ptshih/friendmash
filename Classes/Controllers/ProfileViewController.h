//
//  ProfileViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProfileDelegate <NSObject>
@optional
- (void)shouldPerformLogout;
@end

@class ASINetworkQueue;
@class LauncherViewController;

@interface ProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UITableView *_tableView;
  LauncherViewController *_launcherViewController;
  ASINetworkQueue *_networkQueue;
  NSDictionary *_profileDict;
  NSString *_profileId;
  id <ProfileDelegate> delegate;
}

@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, retain) NSDictionary *profileDict;
@property (nonatomic, retain) NSString *profileId;
@property (nonatomic, assign) id <ProfileDelegate> delegate;

- (IBAction)dismissSettings;

/**
 Initiate logout from Facebook
 This will punt us back to the FBLoginDialog
 */
- (IBAction)logout;

@end
