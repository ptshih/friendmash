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
#import "Constants.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"

@interface LauncherViewController (Private)
/**
 This method checks to see if an OAuth token exists for FB.
 If a token exists, we are already bound and will load, position, and display the left/right faceViews.
 Also send a request to get an NSDictionary of the current user and store it in userDefaults.
 If a token does not exist, remove left/right views from superview and perform FB authorization.
 */
- (void)checkAuthAndGetCurrentUser;

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

@synthesize currentUserRequest = _currentUserRequest;
@synthesize friendsRequest = _friendsRequest;
@synthesize registerFriendsRequest = _registerFriendsRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _facebook = [[Facebook alloc] init];
  }
  return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
//  self.title = NSLocalizedString(@"facemash", @"facemash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
  
  // Check token and authorize
  // [self bindWithFacebook];
}

- (void)viewWillAppear:(BOOL)animated {
  self.navigationController.navigationBar.hidden = YES;
  [self displayLauncher];
}

- (void)displayLauncher {
  if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    _launcherView.hidden = NO;
    [_activityIndicator stopAnimating];
  } else {
    _launcherView.hidden = YES;
    [_activityIndicator startAnimating];
  }
}

- (IBAction)male {
  [self launchFacemashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFacemashWithGender:@"female"];
}

- (IBAction)settings {
  [self unbindWithFacebook];
//  SettingsViewController *svc;
//  if(isDeviceIPad()) {
//    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPad" bundle:nil];
//  } else {
//    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
//  }
//  [self presentModalViewController:svc animated:YES];
//  [svc release];
}

- (IBAction)rankings {
  SettingsViewController *svc;
  if(isDeviceIPad()) {
    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPad" bundle:nil];
  } else {
    svc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
  }
  [self presentModalViewController:svc animated:YES];
  [svc release];
}

- (void)launchFacemashWithGender:(NSString *)gender {
  FacemashViewController *fvc;
  if(isDeviceIPad()) {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPad" bundle:nil];
  } else {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPhone" bundle:nil];
  }
  fvc.gender = gender;
  [self.navigationController pushViewController:fvc animated:YES];
  [fvc release];
}

#pragma mark OAuth / FBConnect
- (void)bindWithFacebook {
  if(![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [_facebook authorize:FB_APP_ID permissions:FB_PERMISSIONS delegate:self view:self.view];
  }
}

- (void)unbindWithFacebook {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

- (void)fbDidLogin {
  // Store the OAuth token
  DLog(@"Received OAuth access token: %@",_facebook.accessToken);
  APP_DELEGATE.fbAccessToken = _facebook.accessToken;
  [[NSUserDefaults standardUserDefaults] setObject:_facebook.accessToken forKey:@"fbAccessToken"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if([[NSUserDefaults standardUserDefaults] boolForKey:@"hasSentFriendsList"]) {
    [self performSelectorOnMainThread:@selector(displayLauncher) withObject:nil waitUntilDone:YES];
  } else {
    [self performSelectorOnMainThread:@selector(getCurrentUserRequest) withObject:nil waitUntilDone:YES];
  }
}

- (void)fbDidNotLogin:(BOOL)cancelled {
  UIAlertView *permissionsAlert = [[UIAlertView alloc] initWithTitle:@"Permissions Error" message:@"We need your permission in order for Facemash to work." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [permissionsAlert show];
  [permissionsAlert autorelease];
  [self bindWithFacebook];
}

- (void)fbDidLogout {
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
      break;
    case 1:
      [_facebook logout:self];
      break;
    default:
      break;
  }
}

/*
 * Get current user's profile from FB
 */
- (void)getCurrentUserRequest {
//  self.currentUserRequest = [OBFacebookOAuthService getCurrentUserWithDelegate:self];
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *fields = @"id,first_name,last_name,name,email,gender,birthday,relationship_status";
  NSString *params = [NSString stringWithFormat:@"access_token=%@&fields=%@", token, fields];
  NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me?%@", params];
  self.currentUserRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.currentUserRequest setRequestMethod:@"GET"];
  [self.currentUserRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [self.currentUserRequest setDelegate:self];
  [self.currentUserRequest startAsynchronous];
}

/*
 * Get current user's friends list from FB
 */
- (void)getFriendsRequest {
//  self.friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];  
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *fields = @"id,first_name,last_name,name,email,gender,birthday,relationship_status";
  NSString *params = [NSString stringWithFormat:@"access_token=%@&fields=%@", token, fields];
  NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me/friends?%@", params];
  self.friendsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.friendsRequest setRequestMethod:@"GET"];
  [self.friendsRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [self.friendsRequest setDelegate:self];
  [self.friendsRequest startAsynchronous];
}

/*
 * Send current user's friends list to facemash
 */
- (void)sendRegisterFriendsRequest {  
  NSDictionary *currentUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUser"];
  NSMutableArray *friendsArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"]];
  [friendsArray insertObject:currentUser atIndex:0];
  
  NSData *postData = [[CJSONDataSerializer serializer] serializeArray:friendsArray];
  NSString *urlString = [NSString stringWithFormat:@"%@/mash/friends/%@", FACEMASH_BASE_URL, [currentUser objectForKey:@"id"]];
  self.registerFriendsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
  [self.registerFriendsRequest setDelegate:self];
  [self.registerFriendsRequest setRequestMethod:@"POST"];
  [self.registerFriendsRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [self.registerFriendsRequest setPostLength:[postData length]];
  [self.registerFriendsRequest setPostBody:(NSMutableData *)postData];
  [self.registerFriendsRequest startAsynchronous];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  if([request isEqual:self.currentUserRequest]) {
    DLog(@"current user request finished");
    
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:responseDict forKey:@"currentUser"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSelectorOnMainThread:@selector(getFriendsRequest) withObject:nil waitUntilDone:YES];
    
  } else if([request isEqual:self.friendsRequest]) {
    DLog(@"friends request finished");
    
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    NSArray *responseArray = [responseDict objectForKey:@"data"];
    [[NSUserDefaults standardUserDefaults] setObject:responseArray forKey:@"friendsArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];

#ifndef USE_OFFLINE_MODE
    [self performSelectorOnMainThread:@selector(sendRegisterFriendsRequest) withObject:nil waitUntilDone:YES];
#endif
  } else if([request isEqual:self.registerFriendsRequest]) {
    DLog(@"register friends request finished");
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSentFriendsList"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelectorOnMainThread:@selector(displayLauncher) withObject:nil waitUntilDone:YES];
  }
  
  // Use when fetching text data
  // NSString *responseString = [request responseString];
  
  // Use when fetching binary data
  // NSData *responseData = [request responseData];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  // NSError *error = [request error];
}

//#pragma mark OBOAuthServiceDelegate
//- (void)oauthService:(Class)service didReceiveAccessToken:(OBOAuthToken *)accessToken {
//  NSLog(@"Got access token:%@ with key: %@ and secret: %@", accessToken, accessToken.key, accessToken.secret);
//  
//  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
//  [[NSUserDefaults standardUserDefaults] synchronize];
//  
//  //store the token
//  [OBOAuthToken persistTokens];
//  [self checkAuthAndGetCurrentUser];
//}


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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [super dealloc];
}


@end
