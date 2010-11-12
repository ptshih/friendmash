//
//  LauncherViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface LauncherViewController : UIViewController <FacebookLoginDelegate> {
  IBOutlet UIView *_launcherView;
  IBOutlet UISwitch *_gameModeSwitch;
  IBOutlet UIView *_splashView;
  IBOutlet UILabel *_splashLabel;
  
  LoginViewController *_loginViewController;
  UIPopoverController *_loginPopoverController;
  
  ASINetworkQueue *_networkQueue;
  ASIHTTPRequest *_currentUserRequest;
  ASIHTTPRequest *_friendsRequest;
  ASIHTTPRequest *_friendsListRequest;
  
  NSURL *_authorizeURL;
  
  NSDictionary *_currentUser;
  NSArray *_friendsArray;
  
  UIButton *_logoutButton;
  
  BOOL _shouldShowLogoutOnAppear;
}

@property (nonatomic,retain) LoginViewController *loginViewController;
@property (nonatomic,retain) UIPopoverController *loginPopoverController;

@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic,assign) ASIHTTPRequest *currentUserRequest;
@property (nonatomic,retain) ASIHTTPRequest *friendsRequest;
@property (nonatomic,retain) ASIHTTPRequest *friendsListRequest;

@property (nonatomic,retain) NSDictionary *currentUser;
@property (nonatomic,retain) NSArray *friendsArray;

@property (nonatomic,assign) BOOL shouldShowLogoutOnAppear;

/**
 Initiate a bind/unbind with Facebook for OAuth token
 */
- (void)bindWithFacebook:(BOOL)animated;
- (void)unbindWithFacebook;

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
