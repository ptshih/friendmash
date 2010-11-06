//
//  LauncherViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import "CJSONSerializer.h"
#import "FBConnect.h"

@interface LauncherViewController : UIViewController <FBSessionDelegate> {
  IBOutlet UIView *_launcherView;
  IBOutlet UIActivityIndicatorView *_activityIndicator;
  IBOutlet UISwitch *_gameModeSwitch;
  ASIHTTPRequest *_currentUserRequest;
  ASIHTTPRequest *_friendsRequest;
  ASIHTTPRequest *_registerFriendsRequest;
  
  Facebook *_facebook;
  
  UIButton *_logoutButton;
}

@property (nonatomic,assign) ASIHTTPRequest *currentUserRequest;
@property (nonatomic,retain) ASIHTTPRequest *friendsRequest;
@property (nonatomic,retain) ASIHTTPRequest *registerFriendsRequest;

/**
 Start mashing with gender = male
 This will launch FacemashViewController and set the gender iVar to male for retrieving the first set
 */
- (IBAction)male;

/**
 Start mashing with gender = female
 This will launch FacemashViewController and set the gender iVar to female for retrieving the first set
 */
- (IBAction)female;

- (IBAction)settings;

- (IBAction)rankings;

@end
