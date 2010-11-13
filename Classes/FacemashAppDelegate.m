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

@interface FacemashAppDelegate (Private)
- (void)checkLastExitDate;
- (void)authenticateWithFacebook:(BOOL)animated;
- (void)fbDidLogout;
@end

@implementation FacemashAppDelegate

@synthesize window;
@synthesize navigationController = _navigationController;
@synthesize loginViewController =_loginViewController;
@synthesize loginPopoverController = _loginPopoverController;
@synthesize launcherViewController = _launcherViewController;
@synthesize touchActive = _touchActive;
@synthesize fbAccessToken = _fbAccessToken;
@synthesize loadingOverlay = _loadingOverlay;

#pragma mark -
#pragma mark Application lifecycle

- (void)authenticateWithFacebook:(BOOL)animated {
  if(_isShowingLogin) return;
  
  if(isDeviceIPad()) {    
    [self.loginPopoverController presentPopoverFromRect:CGRectMake(self.navigationController.view.center.x, 20, 0, 0) inView:self.window permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
  } else {
    
    [self.navigationController presentModalViewController:self.loginViewController animated:animated];
  } 
  _isShowingLogin = YES;
}

- (void)logoutFacebook {
  // Send the expire session request to FB to force logout
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *params = [NSString stringWithFormat:@"access_token=%@",token];
  NSString *baseURLString = @"https://api.facebook.com/method/auth.expireSession";
  NSString *logoutURLString = [NSString stringWithFormat:@"%@?%@", baseURLString, params];
  NSURL *logoutURL = [NSURL URLWithString:logoutURLString];
  NSMutableURLRequest *logoutRequest = [NSMutableURLRequest requestWithURL:logoutURL];
  [logoutRequest setHTTPMethod:@"GET"];
  NSHTTPURLResponse *logoutResponse;
  [NSURLConnection sendSynchronousRequest:logoutRequest returningResponse:&logoutResponse error:nil];
  
  DLog(@"logging out with response code: %d",[logoutResponse statusCode]);
  
  // Delete facebook cookies
  NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]];
  
  for (NSHTTPCookie* cookie in facebookCookies) {
    [cookies deleteCookie:cookie];
  }
  [self fbDidLogout];
}

- (void)fbDidLogout {
  self.fbAccessToken = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastExitDate"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self authenticateWithFacebook:YES];
}


// Called when app launches fresh NOT backgrounded
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  _isShowingLogin = NO;
  _touchActive = NO; // FaceView state stuff
  _loadingOverlay = [[LoadingOverlay alloc] initWithFrame:self.window.frame];
  
  // Create login view controller ivar
  if(isDeviceIPad()) {
    _loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController_iPad" bundle:nil];
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPad" bundle:nil];
    self.loginViewController.contentSizeForViewInPopover = CGSizeMake(self.loginViewController.view.frame.size.width, self.loginViewController.view.frame.size.height);
    _loginPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.loginViewController];
    self.loginPopoverController.delegate = self;
  } else {
    _loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController_iPhone" bundle:nil];
    _launcherViewController = [[LauncherViewController alloc] initWithNibName:@"LauncherViewController_iPhone" bundle:nil];
  }
  self.loginViewController.delegate = self;
  
  // Create navigation controller
  _navigationController = [[UINavigationController alloc] initWithRootViewController:self.launcherViewController];
  self.navigationController.navigationBar.tintColor = RGBCOLOR(59,89,152);
  
  // Override point for customization after app launch. 
  [window addSubview:self.navigationController.view];
  [window makeKeyAndVisible];
  
  // Check last exit so we know if we should auth
  [self checkLastExitDate];

	return YES;
}

- (void)checkLastExitDate {
  // Authenticate with Facebook IF it has been more than 24 hours
  NSDate *lastExitDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastExitDate"];
//  lastExitDate = [NSDate dateWithTimeIntervalSince1970:1288501200];
  
  if(lastExitDate) {
    NSTimeInterval lastExitInterval = [[NSDate date] timeIntervalSinceDate:lastExitDate];
    DLog(@"time interval: %g", lastExitInterval);
    
    // If greater than 24hrs, re-authenticate
    if(lastExitInterval > 86400) {
      [self authenticateWithFacebook:YES]; // authenticate
    } else {
      // Reuse our token from last time
      self.fbAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"fbAccessToken"];
    }
  } else { // this is the first time we launched the app, or we just logged off and tried to login again
    [self authenticateWithFacebook:YES]; // authenticate
  }
}

- (void)dismissLoginView:(BOOL)animated {
  if(isDeviceIPad()) {
    [self.loginPopoverController dismissPopoverAnimated:YES];
  } else {
    [self.loginViewController dismissModalViewControllerAnimated:animated];
  }
  _isShowingLogin = NO;
}

#pragma mark FacebookLoginDelegate
- (void)fbDidLoginWithToken:(NSString *)token andExpiration:(NSDate *)expiration {
  DLog(@"Received OAuth access token: %@",token);
  
  // Set the facebook access token
  // ignore the expiration since we request non-expiring offline access
  self.fbAccessToken = token;
  [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self dismissLoginView:YES];
}

- (void)fbDidNotLoginWithError:(NSError *)error {
  [self dismissLoginView:NO];
  DLog(@"Login failed with error: %@",error);
  UIAlertView *permissionsAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error" message:@"Facebook failed." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [permissionsAlert show];
  [permissionsAlert autorelease];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self authenticateWithFacebook:YES];
}

#pragma mark UIPopoverControllerDelegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
  return NO;
}

#pragma mark Application resume/suspend/exit stuff
// iOS4 ONLY, resuming from background
- (void)applicationWillEnterForeground:(UIApplication *)application {
  [self checkLastExitDate];
}

// Coming back from a locked phone or call
- (void)applicationDidBecomeActive:(UIApplication *)application {
  
}

// Someone received a call or hit the lock button
- (void)applicationWillResignActive:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastExitDate"];
  [[NSUserDefaults standardUserDefaults] synchronize]; 
}

// iOS4 ONLY
- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastExitDate"];
  [[NSUserDefaults standardUserDefaults] synchronize]; 
}

// iOS3 ONLY
- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastExitDate"];
  [[NSUserDefaults standardUserDefaults] synchronize];
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
  if(_loginViewController) [_loginViewController release];
  if(_loginPopoverController) [_loginPopoverController release];
  [_loadingOverlay release];
  [_fbAccessToken release];
  [_launcherViewController release];
  [_navigationController release];
  [window release];
  [super dealloc];
}


@end
