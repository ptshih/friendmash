//
//  FacemashAppDelegate.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashAppDelegate.h"
#import "LauncherViewController.h"
#import "Constants.h"

@implementation FacemashAppDelegate

@synthesize window;
@synthesize navigationController = _navigationController;
@synthesize launcherViewController = _launcherViewController;
@synthesize currentUserDictionary = _currentUserDictionary;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if(isDeviceIPad()) {
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPad" bundle:nil];
  } else {
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPhone" bundle:nil];
  }

  _navigationController = [[UINavigationController alloc] initWithRootViewController:self.launcherViewController];
  self.navigationController.navigationBar.tintColor = RGBCOLOR(59,89,152);
  
  // Current User Dictionary
//  if([[NSUserDefaults standardUserDefaults] valueForKey:@"currentUserDictionary"]) {
//    _currentUserDictionary = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentUserDictionary"];
//  } else {
//    _currentUserDictionary = [[NSMutableDictionary alloc] init];
//    [[NSUserDefaults standardUserDefaults] setObject:self.currentUserDictionary forKey:@"currentUserDictionary"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//  }

//  [[NSUserDefaults standardUserDefaults] setObject:self.currentUserDictionary forKey:@"currentUserDictionary"];
  
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
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
  [_currentUserDictionary release];
  [_launcherViewController release];
  [_navigationController release];
  [window release];
  [super dealloc];
}


@end
