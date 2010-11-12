//
//  SettingsViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsDelegate <NSObject>
@optional
- (void)shouldPerformLogout;
@end

@class LauncherViewController;

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UITableView *_tableView;
  LauncherViewController *_launcherViewController;
  id <SettingsDelegate> delegate;
}

@property (nonatomic, assign) LauncherViewController *launcherViewController;
@property (nonatomic, assign) id <SettingsDelegate> delegate;

- (IBAction)dismissSettings;

/**
 Initiate logout from Facebook
 This will punt us back to the FBLoginDialog
 */
- (IBAction)logout;

@end
