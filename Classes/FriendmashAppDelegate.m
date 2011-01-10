//
//  FriendmashAppDelegate.m
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "FriendmashAppDelegate.h"
#import "LauncherViewController.h"
#import "NSString+Util.h"
#import "Constants.h"
#import "ASIHTTPRequest.h"
#import "RemoteRequest.h"
#import "RemoteOperation.h"
#import "CJSONDeserializer.h"
#import "Appirater.h"

void uncaughtExceptionHandler(NSException *exception) {

}

@interface FriendmashAppDelegate (Private)
- (NSDictionary*)parseURLParams:(NSString *)query;
- (void)sendFacebookAccessToken;
- (void)sendStatsRequest;
- (void)tryLogin;
- (void)startSession;
@end

@implementation FriendmashAppDelegate

@synthesize window;
@synthesize navigationController = _navigationController;
@synthesize loginViewController =_loginViewController;
@synthesize loginPopoverController = _loginPopoverController;
@synthesize launcherViewController = _launcherViewController;
@synthesize currentUserRequest = _currentUserRequest;
@synthesize tokenRequest = _tokenRequest;
@synthesize statsRequest = _statsRequest;
@synthesize fbAccessToken = _fbAccessToken;
@synthesize currentUserId = _currentUserId;
@synthesize currentUser = _currentUser;
@synthesize hostReach = _hostReach;
@synthesize netStatus = _netStatus;
@synthesize reachabilityAlertView = _reachabilityAlertView;
@synthesize sessionKey = _sessionKey;
@synthesize statsArray = _statsArray;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  // If the URL's structure doesn't match the structure used for Facebook authorization, abort.
  if (![[url absoluteString] hasPrefix:[NSString stringWithFormat:@"fb%@://authorize", FB_APP_ID]]) {
    return NO;
  }
  
  NSString *query = [url fragment];
  
  // Version 3.2.3 of the Facebook app encodes the parameters in the query but
  // version 3.3 and above encode the parameters in the fragment. To support
  // both versions of the Facebook app, we try to parse the query if
  // the fragment is missing.
  if (!query) {
    query = [url query];
  }
  
  NSDictionary *params = [self parseURLParams:query];
  NSString *accessToken = [params valueForKey:@"access_token"];
  
  // If the URL doesn't contain the access token, an error has occurred.
  if (!accessToken) {
    NSString *errorReason = [params valueForKey:@"error"];
    
    // If the error response indicates that we should try again using Safari, open
    // the authorization dialog in Safari.
    if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
      [self.loginViewController authorizeWithFBAppAuth:NO safariAuth:YES];
      return YES;
    }
    
    // If the error response indicates that we should try the authorization flow
    // in an inline dialog, do that.
    if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
      [self.loginViewController authorizeWithFBAppAuth:NO safariAuth:NO];
      return YES;
    }
    
    // The facebook app may return an error_code parameter in case it
    // encounters a UIWebViewDelegate error. This should not be treated
    // as a cancel.
    NSString *errorCode = [params valueForKey:@"error_code"];    
    BOOL userDidCancel =
    !errorCode && (!errorReason || [errorReason isEqualToString:@"access_denied"]);
    [self fbDidNotLoginWithError:nil userDidCancel:userDidCancel];
    return YES;
  }
  
  // We have an access token, so parse the expiration date.
  NSString *expTime = [params valueForKey:@"expires_in"];
  NSDate *expirationDate = [NSDate distantFuture];
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal != 0) {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    }
  }
  
//  [self fbDialogLogin:accessToken expirationDate:expirationDate];
  [self fbDidLoginWithToken:accessToken andExpiration:expirationDate];
  return YES;
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
    [[kv objectAtIndex:1]
     stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
  return params;
}

- (void)tryLogin {
  // Check if we even have a valid token
  if(![[NSUserDefaults standardUserDefaults] objectForKey:@"fbAccessToken"]) {
    [self authenticateWithFacebook:NO]; // authenticate
  } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasLoggedIn"]) {
    self.fbAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"fbAccessToken"];
    self.currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"];
    
    // Set Session Start Key
    [self startSession];
    
    // Fire global stats
    [self sendStatsRequest];
  }
}

- (void)dismissLoginView:(BOOL)animated {
  if(isDeviceIPad()) {
    [self.loginPopoverController dismissPopoverAnimated:YES];
  } else {
    [self.loginViewController dismissModalViewControllerAnimated:NO];
  }
  _isShowingLogin = NO;
}

#pragma mark HTTP Requests
- (void)getCurrentUserRequest {
  self.currentUserRequest = [RemoteRequest getFacebookRequestForMeWithDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.currentUserRequest];
}

- (void)sendFacebookAccessToken {
  // Send the newly acquired FB access token to the friendmash server
  // The friendmash server should then use this token to get the user's information and friends list
  NSString *token = [self.fbAccessToken stringWithPercentEscape];
  NSString *params = [NSString stringWithFormat:@"access_token=%@", token];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/token/%@", FRIENDMASH_BASE_URL, self.currentUserId];
//  self.tokenRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  self.tokenRequest = [RemoteRequest postRequestWithBaseURLString:baseURLString andParams:params andPostData:self.currentUser isGzip:NO withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.tokenRequest];
}

- (void)sendStatsRequest {
  DLog(@"sending stats request");
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/globalstats/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.statsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:nil withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.statsRequest];
}


#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  NSInteger statusCode = [request responseStatusCode];
  
  if([request isEqual:self.currentUserRequest]) {
    DLog(@"current user request finished");
    if(statusCode > 200) {
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
    } else {
      self.currentUser = [request responseData];
      self.currentUserId = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil] objectForKey:@"id"];
      
      [[NSUserDefaults standardUserDefaults] setObject:self.currentUserId forKey:@"currentUserId"];
      [[NSUserDefaults standardUserDefaults] synchronize];
      
      // Fire off the server request to friendmash with auth token and userid
      [self sendFacebookAccessToken];
    }
  } else if([request isEqual:self.tokenRequest]) {
    DLog(@"token request finished");
    if(statusCode > 200) {
      _tokenFailedAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [_tokenFailedAlert show];
      [_tokenFailedAlert autorelease];
    } else {
      // Token successfully sent
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedIn"];
      [[NSUserDefaults standardUserDefaults] synchronize];
      
      // dismiss the login view
      [self dismissLoginView:YES];
      
      // Fire global stats
      [self sendStatsRequest];
    }
  } else if([request isEqual:self.statsRequest]) {
    DLog(@"stats request finished");
    if (statusCode > 200) {
      // server error, create an empty stats array
      if(_statsArray) {
        [_statsArray release];
        _statsArray = nil;
      }
      _statsArray = [[NSArray arrayWithObject:@"Error Retrieving Server Statistics"] retain];
    } else {
      NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
      if(_statsArray) {
        [_statsArray release];
        _statsArray = nil;
      }
      _statsArray = [responseArray retain];
    }
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Request Failed with Error: %@", [request error]);
  if([request isEqual:self.currentUserRequest]) {
    _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
    [_networkErrorAlert show];
    [_networkErrorAlert autorelease];
  } else if([request isEqual:self.tokenRequest]) {
    _tokenFailedAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
    [_tokenFailedAlert show];
    [_tokenFailedAlert autorelease];
  }
}

#pragma mark FacebookLoginDelegate
- (void)fbDidLoginWithToken:(NSString *)token andExpiration:(NSDate *)expiration {
  DLog(@"Received OAuth access token: %@",token);

  // Set the facebook access token
  // ignore the expiration since we request non-expiring offline access
  self.fbAccessToken = token;
  [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Set session start key
  [self startSession];
  
  // We need to fire off a GET CURRENT USER request to FB GRAPH API
  [self getCurrentUserRequest];
}

- (void)fbDidNotLoginWithError:(NSError *)error userDidCancel:(BOOL)userDidCancel {
  DLog(@"Login failed with error: %@, user did cancel: %d",error, userDidCancel);
  NSString *errorTitle;
  NSString *errorMessage;
  if(userDidCancel) {
    errorTitle = @"Permissions Error";
    errorMessage = @"Friendmash was unable to login to Facebook. Please try again.";
  } else {
    errorTitle = @"Login Error";
    errorMessage = @"Friendmash is having trouble logging in to Facebook. Please try again.";
  }

  _loginFailedAlert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [_loginFailedAlert show];
  [_loginFailedAlert autorelease];
}

#pragma mark Authentication Display
- (void)authenticateWithFacebook:(BOOL)animated {
  if(_isShowingLogin) {
    [self.loginViewController resetLoginState];
    return;
  }
  
  if(isDeviceIPad()) {
    [self.loginPopoverController presentPopoverFromRect:CGRectMake(self.navigationController.view.center.y, 20, 0, 0) inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
  } else {
    [self.navigationController presentModalViewController:self.loginViewController animated:animated];
  } 
  _isShowingLogin = YES;
}

- (void)logoutFacebook {
#ifdef FB_EXPIRE_TOKEN
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
#endif
  
  // NOTE
  // It might be a good idea to send a request to FM servers to expire/delete this access_token
  
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
  self.currentUserId = nil;
  self.currentUser = nil;
  self.sessionKey = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentUserId"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastExitDate"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hasShownHelp"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hasShownWelcome"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hasLoggedIn"];
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:2] forKey:@"selectedGameMode"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self authenticateWithFacebook:NO];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([alertView isEqual:_networkErrorAlert]) {
    [self getCurrentUserRequest];
  } else if([alertView isEqual:_loginFailedAlert]) {
    [self authenticateWithFacebook:NO];
  } else if([alertView isEqual:_tokenFailedAlert]) {
    [self sendFacebookAccessToken];
  }
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
  static BOOL busyAlertHasIndicator = NO;
  if (alertView != _reachabilityAlertView || busyAlertHasIndicator) return;
  UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  indicator.center = CGPointMake(_reachabilityAlertView.bounds.size.width / 2, _reachabilityAlertView.bounds.size.height - 45);
  [indicator startAnimating];
  [_reachabilityAlertView addSubview:indicator];
  [indicator release];
  busyAlertHasIndicator = YES;
}

#pragma mark UIPopoverControllerDelegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
  return NO;
}

#pragma mark Session
- (void)startSession {
  // Set Session Key
  NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
  NSInteger currentTimestampInteger = floor(currentTimestamp);
  self.sessionKey = [NSString stringWithFormat:@"%d", currentTimestampInteger]; 
}

#pragma mark Application resume/suspend/exit stuff
// Called when app launches fresh NOT backgrounded
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  // Detect Upgrade
  if ([[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"]) {
    if (![[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"]]) {
      [[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasShownHelp"];
      if ([[NSUserDefaults standardUserDefaults] objectForKey:@"fbAccessToken"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedIn"]; // Force logged in for updates from 1.1 -> 1.X
      } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasLoggedIn"]; // Force logged in for updates from 1.1 -> 1.X
      }
    }
  }

  // Uncaught Exception Handler
  NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
  
  // Default new users to Social Network mode
  if (![[NSUserDefaults standardUserDefaults] objectForKey:@"selectedGameMode"]) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:2] forKey:@"selectedGameMode"];
  }
  
  // Has Logged In
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasLoggedIn"]) {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasLoggedIn"];
  }
  
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  _isShowingLogin = NO;
  
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
  
  // Reachability
  _reachabilityAlertView = [[UIAlertView alloc] initWithTitle:@"No Network Connection" message:@"An active network connection is required to play Friendmash." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
  
	_hostReach = [[Reachability reachabilityWithHostName: @"www.apple.com"] retain];
  _netStatus = 0; // default netstatus to 0
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
  [self.hostReach startNotifier];
  
  _statsArray = [[NSArray arrayWithObject:@"Welcome to Friendmash!"] retain];
  
  // Appirater
  [Appirater appLaunched:YES];
  
  // Override point for customization after app launch. 
  [window addSubview:self.navigationController.view];
  [window makeKeyAndVisible];
  
	return YES;
}

// iOS4 ONLY, resuming from background
- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Appirater
  [Appirater appEnteredForeground:YES];
}

// Coming back from a locked phone or call
- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self tryLogin];
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

#pragma mark Reachability
//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification *)note {
	Reachability *curReach = [note object];
	self.netStatus = [curReach currentReachabilityStatus];
	
	if(curReach == self.hostReach) {
		if(self.netStatus > kNotReachable) {
      if(self.reachabilityAlertView && self.reachabilityAlertView.visible) {
        [self.reachabilityAlertView dismissWithClickedButtonIndex:0 animated:YES];
      }
		} else {
      [self.reachabilityAlertView show];
    }
	}
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  /*
   Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
   */
}

- (void)dealloc {
  if(_tokenRequest) {
    [_tokenRequest clearDelegatesAndCancel];
    [_tokenRequest release];
  }
  if(_currentUserRequest) {
    [_currentUserRequest clearDelegatesAndCancel];
    [_currentUserRequest release];
  }
  
  if(_statsRequest) {
    [_statsRequest clearDelegatesAndCancel];
    [_statsRequest release];
  }
  
  RELEASE_SAFELY(_loginViewController);
  RELEASE_SAFELY(_loginPopoverController);
  RELEASE_SAFELY(_fbAccessToken);
  RELEASE_SAFELY(_currentUserId);
  RELEASE_SAFELY(_currentUser);
  RELEASE_SAFELY(_launcherViewController);
  RELEASE_SAFELY(_navigationController);
  RELEASE_SAFELY(_hostReach);
  RELEASE_SAFELY(_reachabilityAlertView);
  RELEASE_SAFELY(_sessionKey);

  [window release];
  [super dealloc];
}


@end
