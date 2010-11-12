//
//  FacemashAppDelegate.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FacemashViewController;
@class LauncherViewController;
@class LoadingOverlay;

@interface FacemashAppDelegate : NSObject <UIApplicationDelegate> {
  UIWindow *window;
  UINavigationController *_navigationController;
  LauncherViewController *_launcherViewController;
  BOOL _touchActive;
  
  NSString *_fbAccessToken;
  
  LoadingOverlay *_loadingOverlay;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet LauncherViewController *launcherViewController;
@property (nonatomic, assign) BOOL touchActive;
@property (nonatomic, retain) NSString *fbAccessToken;
@property (nonatomic, retain) LoadingOverlay *loadingOverlay;

- (void)showLoadingOverlay;
- (void)hideLoadingOverlay;
  
@end

