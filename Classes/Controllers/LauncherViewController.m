    //
//  LauncherViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "FacemashViewController.h"
#import "SettingsViewController.h"
#import "RankingsViewController.h"
#import "Constants.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"

@interface LauncherViewController (Private)
- (void)fbDidLogout;

- (void)getCurrentUserRequest;

/**
 This method creates and pushes the FacemashViewController and sets it's iVar to the designated gender
 */
- (void)launchFacemashWithGender:(NSString *)gender;

/**
 Shows the gender selection splash screen
 */
- (void)displayLauncher;

@end

@implementation LauncherViewController

@synthesize loginViewController = _loginViewController;
@synthesize networkQueue = _networkQueue;
@synthesize currentUserRequest = _currentUserRequest;
@synthesize friendsRequest = _friendsRequest;
@synthesize friendsListRequest = _friendsListRequest;
@synthesize currentUser = _currentUser;
@synthesize friendsArray = _friendsArray;
@synthesize shouldShowLogoutOnAppear = _shouldShowLogoutOnAppear;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _currentUser = [[NSDictionary alloc] init];
    _friendsArray = [[NSArray alloc] init];
    
    _loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController_iPhone" bundle:nil];
    self.loginViewController.delegate = self;
    
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
    
    _shouldShowLogoutOnAppear = NO;
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
//  self.title = NSLocalizedString(@"facemash", @"facemash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
  
  // Check token and authorize
#ifndef OFFLINE_DEBUG
  [self bindWithFacebook];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
  self.navigationController.navigationBar.hidden = YES;
  [self displayLauncher];
  
  if(self.shouldShowLogoutOnAppear) {
    self.shouldShowLogoutOnAppear = NO;
    UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    [logoutAlert show];
    [logoutAlert autorelease];
  }
}

- (void)displayLauncher {
#ifdef OFFLINE_DEBUG
  _launcherView.hidden = NO;
  [_activityIndicator stopAnimating];
#else
  if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    _launcherView.hidden = NO;
    [_activityIndicator stopAnimating];
  } else {
    _launcherView.hidden = YES;
    [_activityIndicator startAnimating];
  }
#endif
}

- (IBAction)male {
  [self launchFacemashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFacemashWithGender:@"female"];
}

- (IBAction)settings {
  SettingsViewController *svc;
  if(isDeviceIPad()) {
    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPad" bundle:nil];
  } else {
    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
  }
  svc.launcherViewController = self;
  [self presentModalViewController:svc animated:YES];
  [svc release];
}

- (IBAction)rankings {
  RankingsViewController *rvc;
  if(isDeviceIPad()) {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPad" bundle:nil];
  } else {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPhone" bundle:nil];
  }
  rvc.launcherViewController = self;
  [self presentModalViewController:rvc animated:YES];
  [rvc release];
}

- (void)launchFacemashWithGender:(NSString *)gender {
  FacemashViewController *fvc;
  if(isDeviceIPad()) {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPad" bundle:nil];
  } else {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPhone" bundle:nil];
  }
  fvc.gender = gender;
  fvc.gameMode = _gameModeSwitch.on;
  [self.navigationController pushViewController:fvc animated:YES];
  [fvc release];
}

#pragma mark Facebook Login/Logout
- (void)bindWithFacebook {
  if(![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [self presentModalViewController:self.loginViewController animated:YES];
  } else {
  }
}

- (void)unbindWithFacebook {
  // Delete facebook cookies
  NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]];
  
  for (NSHTTPCookie* cookie in facebookCookies) {
    [cookies deleteCookie:cookie];
  }
  [self fbDidLogout];
}

- (void)fbDidLoginWithToken:(NSString *)token {
  [self.loginViewController dismissModalViewControllerAnimated:YES];
  // Store the OAuth token
  DLog(@"Received OAuth access token: %@",token);
  APP_DELEGATE.fbAccessToken = token;
  
  [[NSUserDefaults standardUserDefaults] setObject:APP_DELEGATE.fbAccessToken forKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if([[NSUserDefaults standardUserDefaults] boolForKey:@"hasSentFriendsList"]) {
    [self performSelectorOnMainThread:@selector(displayLauncher) withObject:nil waitUntilDone:YES];
  } else {
    [self performSelectorOnMainThread:@selector(getCurrentUserRequest) withObject:nil waitUntilDone:YES];
  }
}

- (void)fbDidNotLoginWithError:(NSError *)error {
  [self.loginViewController dismissModalViewControllerAnimated:YES];
  DLog(@"Login failed with error: %@",error);
  UIAlertView *permissionsAlert = [[UIAlertView alloc] initWithTitle:@"Permissions Error" message:@"We need your permission in order for Facemash to work." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [permissionsAlert show];
  [permissionsAlert autorelease];
}

- (void)fbDidLogout {
  APP_DELEGATE.fbAccessToken = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasSentFriendsList"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self bindWithFacebook];
  [self displayLauncher];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      [self bindWithFacebook];
      break;
    case 1:
      [self unbindWithFacebook];;
    default:
      break;
  }
}

/*
 * Get current user's profile from FB
 */
- (void)getCurrentUserRequest {
  self.currentUserRequest = [RemoteRequest getFacebookRequestForMeWithDelegate:nil];
  [self.networkQueue addOperation:self.currentUserRequest];
  [self.networkQueue go];
}

/*
 * Get current user's friends list from FB
 */
- (void)getFriendsRequest {
  self.friendsRequest = [RemoteRequest getFacebookRequestForFriendsWithDelegate:nil];
  [self.networkQueue addOperation:self.friendsRequest];
  [self.networkQueue go];
}

/*
 * Send current user's friends list to facemash
 */
- (void)postFriendsRequest {  
  NSMutableArray *allFriendsArray = [NSMutableArray arrayWithArray:self.friendsArray];
  [allFriendsArray insertObject:self.currentUser atIndex:0];
  
  NSData *postData = [[CJSONDataSerializer serializer] serializeArray:allFriendsArray];
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *params = [NSString stringWithFormat:@"access_token=%@", token];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/friends/%@", FACEMASH_BASE_URL, [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  
  self.friendsListRequest = [RemoteRequest postRequestWithBaseURLString:baseURLString andParams:params andPostData:postData withDelegate:nil];
  [self.networkQueue addOperation:self.friendsListRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  if([request isEqual:self.currentUserRequest]) {
    DLog(@"current user request finished");
    
    self.currentUser = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[self.currentUser objectForKey:@"id"] forKey:@"currentUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSelectorOnMainThread:@selector(getFriendsRequest) withObject:nil waitUntilDone:YES];
    
  } else if([request isEqual:self.friendsRequest]) {
    DLog(@"friends request finished");
    
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    self.friendsArray = [responseDict objectForKey:@"data"];
//    [[NSUserDefaults standardUserDefaults] setObject:responseArray forKey:@"friendsArray"];
//    [[NSUserDefaults standardUserDefaults] synchronize];

#ifndef USE_OFFLINE_MODE
    [self performSelectorOnMainThread:@selector(postFriendsRequest) withObject:nil waitUntilDone:YES];
#endif
  } else if([request isEqual:self.friendsListRequest]) {
    DLog(@"register friends request finished");
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSentFriendsList"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelectorOnMainThread:@selector(displayLauncher) withObject:nil waitUntilDone:YES];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  DLog(@"Request Failed with Error: %@", [request error]);
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark Memory Management
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) return YES;
  else return NO;
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
}


- (void)dealloc {
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  [_networkQueue release];
  if(_currentUser) [_currentUser release];
  if(_friendsArray) [_friendsArray release];
  if(_loginViewController) [_loginViewController release];
  [super dealloc];
}

@end
