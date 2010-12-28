    //
//  LauncherViewController.m
//  Friendmash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "LauncherViewController.h"
#import "FriendmashViewController.h"
#import "ProfileViewController.h"
#import "RankingsViewController.h"
#import "AboutViewController.h"
#import "Constants.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"
#import "CJSONDeserializer.h"
#import <QuartzCore/QuartzCore.h>

#define STATS_SCROLL_OFFSET 20.0

@interface LauncherViewController (Private)

/**
 This method creates and pushes the FriendmashViewController and sets it's iVar to the designated gender
 */
- (void)launchFriendmashWithGender:(NSString *)gender;

- (void)sendStatsRequestWithDelegate:(id)delegate;
- (void)setupStatsScroll;
- (void)startStatsAnimation;
- (void)shouldStartStatsAnimation;
- (void)setupGameModeAtIndex:(NSInteger)index;

@end

@implementation LauncherViewController

@synthesize launcherView = _launcherView;
@synthesize statsLabel = _statsLabel;
@synthesize statsNextLabel = _statsNextLabel;
@synthesize networkQueue = _networkQueue;
@synthesize statsRequest = _statsRequest;
@synthesize statsArray = _statsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _isVisible = NO;
    _isResume = NO;
    _isAnimating = NO;
    _statsCounter = 0;
    _gameMode = FriendmashGameModeNormal;
    _statsArray = [[NSArray arrayWithObject:@"Welcome to Friendmash!"] retain];
    
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
  
  [self setupGameModeAtIndex:[[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedGameMode"] integerValue]];
  
  self.navigationController.navigationBar.hidden = YES;
  
  self.title = NSLocalizedString(@"friendmash", @"friendmash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
  [self setupStatsScroll];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  self.navigationController.navigationBar.hidden = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendStatsRequestWithDelegate:) name:kRequestGlobalStats object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeFromBackground) name:kAppWillEnterForeground object:nil];  
  _isVisible = YES;
  
  // Start Stats Animation
  // I use userdefaults here because when the app launches, APP_DELEGATE hasn't set it's currentUserId ivar yet
  // Because LauncherViewController gets shown before we even try to login
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasDownloadedStats"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]) {
    [self sendStatsRequestWithDelegate:self];
  } else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]) {
    [self shouldStartStatsAnimation];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kRequestGlobalStats object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kAppWillEnterForeground object:nil];
  
  _isVisible = NO;
  _isAnimating = NO;
  
  // Stop Stats Animation
  [self.statsLabel.layer removeAllAnimations];
  [self.statsNextLabel.layer removeAllAnimations];
}

- (void)resumeFromBackground {
  if([[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]) {
    _isResume = YES;
    [self sendStatsRequestWithDelegate:self];
  }
}

- (void)setupStatsScroll {
  _statsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, STATS_SCROLL_OFFSET)];
  _statsNextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -STATS_SCROLL_OFFSET, self.view.frame.size.width, STATS_SCROLL_OFFSET)];
  self.statsLabel.backgroundColor = [UIColor clearColor];
  self.statsLabel.textColor = [UIColor whiteColor];
  self.statsLabel.textAlignment = UITextAlignmentCenter;
  self.statsLabel.text = @"Welcome to Friendmash";
  self.statsNextLabel.backgroundColor = [UIColor clearColor];
  self.statsNextLabel.textColor = [UIColor whiteColor];
  self.statsNextLabel.textAlignment = UITextAlignmentCenter;
  
  if (isDeviceIPad()) {
    self.statsLabel.font = [UIFont systemFontOfSize:18.0];
    self.statsNextLabel.font = [UIFont systemFontOfSize:18.0];
  } else {
    self.statsLabel.font = [UIFont systemFontOfSize:14.0];
    self.statsNextLabel.font = [UIFont systemFontOfSize:14.0];
  }
  
  [_statsView addSubview:self.statsLabel];
  [_statsView addSubview:self.statsNextLabel];
}

- (void)shouldStartStatsAnimation {
  if (_isResume) {
    _isResume = NO;
  } else if (!_isAnimating) {
    [self startStatsAnimation];
  }
}

- (void)startStatsAnimation {
  _isAnimating = YES;
//  Random
//  self.statsLabel.text = self.statsNextLabel.text ? self.statsNextLabel.text : [self.statsArray objectAtIndex:(arc4random() % [self.statsArray count])];
//  self.statsNextLabel.text = [self.statsArray objectAtIndex:(arc4random() % [self.statsArray count])];
  if (self.statsNextLabel.text) {
    self.statsLabel.text = self.statsNextLabel.text;
  } else {
    _statsCounter = 0;
    self.statsLabel.text = [self.statsArray objectAtIndex:_statsCounter];
    _statsCounter++;
  }
  if (_statsCounter == [self.statsArray count]) _statsCounter = 0;
  self.statsNextLabel.text = [self.statsArray objectAtIndex:_statsCounter];
  if ([self.statsArray count] > 1) {
    _statsCounter++;
  }
  self.statsLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, STATS_SCROLL_OFFSET);
  self.statsNextLabel.frame = CGRectMake(0, -STATS_SCROLL_OFFSET, self.view.frame.size.width, STATS_SCROLL_OFFSET);
  
  [UIView beginAnimations:@"StatsScroll" context:nil];
	[UIView setAnimationDelegate:self];
  [UIView setAnimationWillStartSelector:@selector(statsScrollStarted)];
  [UIView setAnimationDidStopSelector:@selector(statsScrollFinished)];
//	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDelay:3.0];
	[UIView setAnimationDuration:1.0]; // Fade out is configurable in seconds (FLOAT)
  self.statsLabel.frame = CGRectMake(0, STATS_SCROLL_OFFSET, self.view.frame.size.width, STATS_SCROLL_OFFSET);
  self.statsNextLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, STATS_SCROLL_OFFSET);
	[UIView commitAnimations];
}

- (void)statsScrollStarted {
//  DLog(@"start");
}

- (void)statsScrollFinished {
//  DLog(@"finished");
  if(_isVisible) {
    [self startStatsAnimation];
  }
}

- (IBAction)modeSelect:(UIButton *)modeButton {
  UIActionSheet *modeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose a Game Mode" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Show Everyone", @"Show Friends", @"Show Social Network", nil];
  modeActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  [modeActionSheet showInView:self.view];
  [modeActionSheet autorelease];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self setupGameModeAtIndex:buttonIndex];
  
  // Remember the user's mode setting
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:_gameMode] forKey:@"selectedGameMode"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupGameModeAtIndex:(NSInteger)index {
  switch (index) {
    case 0:
      _gameMode = FriendmashGameModeNormal;
      [_modeButton setTitle:@"Everyone" forState:UIControlStateNormal];
      DLog(@"everyone");
      break;
    case 1:
      _gameMode = FriendmashGameModeFriends;
      [_modeButton setTitle:@"Friends" forState:UIControlStateNormal];
      DLog(@"friends");
      break;
    case 2:
      _gameMode = FriendmashGameModeNetwork;
      [_modeButton setTitle:@"Social Network" forState:UIControlStateNormal];
      DLog(@"network");
      break;
    default:
      break;
  }
}

- (IBAction)male {
  [FlurryAPI logEvent:@"launcherMale"];
  [self launchFriendmashWithGender:@"male"];
}
- (IBAction)female {
  [FlurryAPI logEvent:@"launcherFemale"];
  [self launchFriendmashWithGender:@"female"];
}

- (IBAction)about {
  [FlurryAPI logEvent:@"launcherAbout"];
  AboutViewController *avc;
  if(isDeviceIPad()) {
    avc = [[AboutViewController alloc] initWithNibName:@"AboutViewController_iPad" bundle:nil];
    avc.modalPresentationStyle = UIModalPresentationFormSheet;
  } else {
    avc = [[AboutViewController alloc] initWithNibName:@"AboutViewController_iPhone" bundle:nil];
  }
  [self presentModalViewController:avc animated:YES];
  [avc release]; 
}

- (IBAction)profile {  
  [FlurryAPI logEvent:@"launcherProfile"];
  ProfileViewController *pvc;
  if(isDeviceIPad()) {
    pvc = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController_iPad" bundle:nil];
    pvc.modalPresentationStyle = UIModalPresentationFormSheet;
  } else {
    pvc = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController_iPhone" bundle:nil];
  }
  pvc.launcherViewController = self;
  pvc.delegate = self;
  pvc.profileId = APP_DELEGATE.currentUserId;
  [self presentModalViewController:pvc animated:YES];
  [pvc release];
}

- (IBAction)rankings {
  [FlurryAPI logEvent:@"launcherRankings"];
  RankingsViewController *rvc;
  if(isDeviceIPad()) {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPad" bundle:nil];
    rvc.modalPresentationStyle = UIModalPresentationFormSheet;
  } else {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPhone" bundle:nil];
  }
  rvc.launcherViewController = self;
  rvc.gameMode = FriendmashGameModeNormal; // NOTE: force this to normal mode
  [self presentModalViewController:rvc animated:YES];
  [rvc release];
}

- (void)launchFriendmashWithGender:(NSString *)gender {
  FriendmashViewController *fvc;
  if(isDeviceIPad()) {
    fvc = [[FriendmashViewController alloc] initWithNibName:@"FriendmashViewController_iPad" bundle:nil];
  } else {
    fvc = [[FriendmashViewController alloc] initWithNibName:@"FriendmashViewController_iPhone" bundle:nil];
  }
  fvc.gender = gender;
  fvc.gameMode = _gameMode;
  [self.navigationController pushViewController:fvc animated:YES];
  [fvc release];
}

#pragma mark SettingsDelegate
- (void)shouldPerformLogout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  // logout
  switch (buttonIndex) {
    case 0:
      break;
    case 1:
      [APP_DELEGATE logoutFacebook];
      break;
    default:
      break;
  }
}

#pragma mark Server Requests
- (void)sendStatsRequestWithDelegate:(id)delegate {
  DLog(@"sending stats request");
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/globalstats/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.statsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:nil withDelegate:nil];
  [self.networkQueue addOperation:self.statsRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    DLog(@"FMVC status code not 200 in request finished, response: %@", [request responseString]);
    
    // server error, create an empty stats array
    if(_statsArray) {
      [_statsArray release];
      _statsArray = nil;
    }
    _statsArray = [[NSArray arrayWithObject:@"Error Retrieving Server Statistics"] retain];
  } else {
    if([request isEqual:self.statsRequest]) {
      DLog(@"stats request finished");
      NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
      if(_statsArray) {
        [_statsArray release];
        _statsArray = nil;
      }
      _statsArray = [responseArray retain];
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasDownloadedStats"];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [self performSelectorOnMainThread:@selector(shouldStartStatsAnimation) withObject:nil waitUntilDone:YES];
    }
  }
  
//  [self startStatsAnimation];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Stats Request Failed with Error: %@", [request error]);
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}


#pragma mark Memory Management
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return UIInterfaceOrientationIsLandscape(interfaceOrientation);
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
  if(_statsRequest) {
    [_statsRequest clearDelegatesAndCancel];
    [_statsRequest release];
  }
  
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  
  if(_statsArray) [_statsArray release];
  if(_launcherView) [_launcherView release];
  if(_modeButton) [_modeButton release];
  if(_statsView) [_statsView release];
  if(_statsLabel) [_statsLabel release];
  if(_statsNextLabel) [_statsNextLabel release];
  [super dealloc];
}

@end
