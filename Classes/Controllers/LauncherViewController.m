    //
//  LauncherViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "FacemashViewController.h"
#import "ProfileViewController.h"
#import "RankingsViewController.h"
#import "Constants.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"

@interface LauncherViewController (Private)

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

@synthesize networkQueue = _networkQueue;
@synthesize currentUserRequest = _currentUserRequest;
@synthesize friendsRequest = _friendsRequest;
@synthesize friendsListRequest = _friendsListRequest;
@synthesize currentUser = _currentUser;
@synthesize friendsArray = _friendsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _currentUser = [[NSDictionary alloc] init];
    _friendsArray = [[NSArray alloc] init];
    
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationController.navigationBar.hidden = YES;
  
//  self.title = NSLocalizedString(@"facemash", @"facemash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
}

- (void)viewWillAppear:(BOOL)animated {
//  self.navigationController.navigationBar.hidden = YES;
  [self displayLauncher];
}

- (void)displayLauncher {
  _launcherView.hidden = NO;
  _splashView.hidden = YES;
}

- (IBAction)male {
  [self launchFacemashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFacemashWithGender:@"female"];
}

- (IBAction)profile {
  ProfileViewController *pvc;
  if(isDeviceIPad()) {
    pvc = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController_iPad" bundle:nil];
    pvc.modalPresentationStyle = UIModalPresentationFormSheet;
  } else {
    pvc = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController_iPhone" bundle:nil];
  }
  pvc.launcherViewController = self;
  pvc.delegate = self;
  pvc.profileId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"];
  [self presentModalViewController:pvc animated:YES];
  [pvc release];
}

- (IBAction)rankings {
  RankingsViewController *rvc;
  if(isDeviceIPad()) {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPad" bundle:nil];
    rvc.modalPresentationStyle = UIModalPresentationFormSheet;
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

#pragma mark SettingsDelegate
- (void)shouldPerformLogout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

/*
 * Get current user's profile from FB
 */
- (void)getCurrentUserRequest {
  _splashLabel.text = NSLocalizedString(@"Retrieving your Facebook profile...", @"Retrieving your Facebook profile...");
  self.currentUserRequest = [RemoteRequest getFacebookRequestForMeWithDelegate:nil];
  [self.networkQueue addOperation:self.currentUserRequest];
  [self.networkQueue go];
}

/*
 * Get current user's friends list from FB
 */
- (void)getFriendsRequest {
  _splashLabel.text = NSLocalizedString(@"Retrieving your Facebook friends...", @"Retrieving your Facebook friends...");
  self.friendsRequest = [RemoteRequest getFacebookRequestForFriendsWithDelegate:nil];
  [self.networkQueue addOperation:self.friendsRequest];
  [self.networkQueue go];
}

/*
 * Send current user's friends list to facemash
 */
- (void)postFriendsRequest {  
  _splashLabel.text = NSLocalizedString(@"Sending data to Facemash...", @"Sending data to Facemash...");
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
  NSInteger statusCode = [request responseStatusCode];

  if([request isEqual:self.currentUserRequest]) {
    DLog(@"current user request finished");
    if(statusCode > 200) {
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
      return;
    }
    
    self.currentUser = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[self.currentUser objectForKey:@"id"] forKey:@"currentUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSelectorOnMainThread:@selector(getFriendsRequest) withObject:nil waitUntilDone:YES];
    
  } else if([request isEqual:self.friendsRequest]) {
    DLog(@"friends request finished");
    if(statusCode > 200) {
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
      return;
    }
    
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil];
    self.friendsArray = [responseDict objectForKey:@"data"];
//    [[NSUserDefaults standardUserDefaults] setObject:responseArray forKey:@"friendsArray"];
//    [[NSUserDefaults standardUserDefaults] synchronize];

#ifndef USE_OFFLINE_MODE
    [self performSelectorOnMainThread:@selector(postFriendsRequest) withObject:nil waitUntilDone:YES];
#endif
  } else if([request isEqual:self.friendsListRequest]) {
    DLog(@"register friends request finished");
    if(statusCode > 200) {
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
      return;
    }
    
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

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([alertView isEqual:_networkErrorAlert]) {
    [self getCurrentUserRequest];
  } else {
    // logout
    [APP_DELEGATE logoutFacebook];
  }
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
  [super dealloc];
}

@end
