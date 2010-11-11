//
//  LauncherViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface LauncherViewController : UIViewController {
  IBOutlet UIView *_fbDialogView;
  IBOutlet UIWebView *_facebookWebView;
  IBOutlet UIView *_launcherView;
  IBOutlet UIActivityIndicatorView *_activityIndicator;
  IBOutlet UISwitch *_gameModeSwitch;
  ASINetworkQueue *_networkQueue;
  ASIHTTPRequest *_currentUserRequest;
  ASIHTTPRequest *_friendsRequest;
  ASIHTTPRequest *_friendsListRequest;
  
  NSURL *_authorizeURL;
  
  NSDictionary *_currentUser;
  NSArray *_friendsArray;
  
  UIButton *_logoutButton;
}

@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic,assign) ASIHTTPRequest *currentUserRequest;
@property (nonatomic,retain) ASIHTTPRequest *friendsRequest;
@property (nonatomic,retain) ASIHTTPRequest *friendsListRequest;

@property (nonatomic,retain) NSDictionary *currentUser;
@property (nonatomic,retain) NSArray *friendsArray;

/**
 Initiate a bind/unbind with Facebook for OAuth token
 */
- (void)bindWithFacebook;
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
