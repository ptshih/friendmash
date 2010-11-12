//
//  FacemashAppDelegate.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashAppDelegate.h"
#import "LauncherViewController.h"
#import "LoadingOverlay.h"
#import "Constants.h"

@implementation FacemashAppDelegate

@synthesize window;
@synthesize navigationController = _navigationController;
@synthesize launcherViewController = _launcherViewController;
@synthesize touchActive = _touchActive;
@synthesize fbAccessToken = _fbAccessToken;
@synthesize loadingOverlay = _loadingOverlay;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  self.fbAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"fbAccessToken"];
  
  _touchActive = NO;
  
  // NOTE: Currently this forces the friends list to be sent every app launch
  // This needs to be changed before shipping
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasSentFriendsList"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  _loadingOverlay = [[LoadingOverlay alloc] initWithFrame:self.window.frame];
  
  if(isDeviceIPad()) {
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPad" bundle:nil];
  } else {
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPhone" bundle:nil];
  }

  _navigationController = [[UINavigationController alloc] initWithRootViewController:self.launcherViewController];
  self.navigationController.navigationBar.tintColor = RGBCOLOR(59,89,152);
  
  // Override point for customization after app launch. 
  [window addSubview:self.navigationController.view];
  [window makeKeyAndVisible];

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark LoadingOverlay
- (void)showLoadingOverlay {
	[self.window addSubview:self.loadingOverlay];
}

- (void)hideLoadingOverlay {
	[self.loadingOverlay removeFromSuperview];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
  [_loadingOverlay release];
  [_fbAccessToken release];
  [_launcherViewController release];
  [_navigationController release];
  [window release];
  [super dealloc];
}


@end
