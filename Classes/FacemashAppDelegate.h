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
@class LoadingOverlay;

@interface FacemashAppDelegate : NSObject <UIApplicationDelegate, FacebookLoginDelegate, UIPopoverControllerDelegate> {
  UIWindow *window;
  UINavigationController *_navigationController;
  LoginViewController *_loginViewController;
  LauncherViewController *_launcherViewController;
  UIPopoverController *_loginPopoverController;
  BOOL _touchActive;
  
  NSString *_fbAccessToken;
  
  LoadingOverlay *_loadingOverlay;
  
  BOOL _isShowingLogin;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) LoginViewController *loginViewController;
@property (nonatomic,retain) UIPopoverController *loginPopoverController;
@property (nonatomic, retain) IBOutlet LauncherViewController *launcherViewController;
@property (nonatomic, assign) BOOL touchActive;
@property (nonatomic, retain) NSString *fbAccessToken;
@property (nonatomic, retain) LoadingOverlay *loadingOverlay;

- (void)logoutFacebook;
- (void)showLoadingOverlay;
- (void)hideLoadingOverlay;
  
@end

