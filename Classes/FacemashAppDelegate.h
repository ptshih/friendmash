//
//  FacemashAppDelegate.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@class FacemashViewController;
@class LauncherViewController;
@class ASIHTTPRequest;
@class ASINetworkQueue;
@class LoadingOverlay;

@interface FacemashAppDelegate : NSObject <UIApplicationDelegate, FacebookLoginDelegate, UIPopoverControllerDelegate> {
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

  LoadingOverlay *_loadingOverlay;
  BOOL _touchActive;
  BOOL _isShowingLogin;
  
  UIAlertView *_networkErrorAlert;
  NSInteger _tokenRetryCount;
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
@property (nonatomic, retain) LoadingOverlay *loadingOverlay;
@property (nonatomic, assign) BOOL touchActive;

- (void)logoutFacebook;
- (void)showLoadingOverlay;
- (void)hideLoadingOverlay;
  
@end

