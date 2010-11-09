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

@interface FacemashAppDelegate : NSObject <UIApplicationDelegate> {
  UIWindow *window;
  UINavigationController *_navigationController;
  LauncherViewController *_launcherViewController;
  BOOL _touchActive;
  
  NSString *_fbAccessToken;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet LauncherViewController *launcherViewController;
@property (nonatomic, assign) BOOL touchActive;
@property (nonatomic, retain) NSString *fbAccessToken;

@end

