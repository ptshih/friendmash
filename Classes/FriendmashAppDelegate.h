//
//  FriendmashAppDelegate.h
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "Reachability.h"

@class FriendmashViewController;
@class LauncherViewController;
@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface FriendmashAppDelegate : NSObject <UIApplicationDelegate, FacebookLoginDelegate, UIPopoverControllerDelegate> {
  UIWindow *window;
  UINavigationController *_navigationController;
  LoginViewController *_loginViewController;
  LauncherViewController *_launcherViewController;
  UIPopoverController *_loginPopoverController;
  ASINetworkQueue *_networkQueue;
  ASIHTTPRequest *_currentUserRequest;
  ASIHTTPRequest *_tokenRequest;
  NSString *_fbAccessToken;
  NSString *_currentUserId;
  NSData *_currentUser;

  BOOL _touchActive;
  BOOL _isShowingLogin;
  
  UIAlertView *_networkErrorAlert;
  UIAlertView *_loginFailedAlert;
  UIAlertView *_tokenFailedAlert;
  NSInteger _tokenRetryCount;
  
  Reachability *_hostReach;
	NetworkStatus _netStatus;
  UIAlertView *_reachabilityAlertView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) LoginViewController *loginViewController;
@property (nonatomic, retain) UIPopoverController *loginPopoverController;
@property (nonatomic, retain) IBOutlet LauncherViewController *launcherViewController;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, retain) ASIHTTPRequest *currentUserRequest;
@property (nonatomic, retain) ASIHTTPRequest *tokenRequest;
@property (nonatomic, retain) NSString *fbAccessToken;
@property (nonatomic, retain) NSString *currentUserId;
@property (nonatomic, retain) NSData *currentUser;
@property (nonatomic, assign) BOOL touchActive;

@property (nonatomic, retain) Reachability *hostReach;
@property (nonatomic, assign) NetworkStatus netStatus;
@property (nonatomic, retain) UIAlertView *reachabilityAlertView;

- (void)authenticateWithFacebook:(BOOL)animated;
- (void)logoutFacebook;
- (void)fbDidLogout;
  
@end

