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
#import "MashCache.h"

#define STATS_SCROLL_OFFSET 20.0

@interface LauncherViewController (Private)

/**
 This method creates and pushes the FriendmashViewController and sets it's iVar to the designated gender
 */
- (void)launchFriendmashWithGender:(NSString *)gender;

- (void)setupStatsScroll;
- (void)startStatsAnimation;
- (void)shouldStartStatsAnimation;
- (void)setupGameModeAtIndex:(NSInteger)index;
- (void)setupGameMode;

@end

@implementation LauncherViewController

@synthesize launcherView = _launcherView;
@synthesize modeButton = _modeButton;
@synthesize statsView = _statsView;
@synthesize statsLabel = _statsLabel;
@synthesize statsNextLabel = _statsNextLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _isVisible = NO;
    _isAnimating = NO;
    _statsCounter = 0;
    _gameMode = FriendmashGameModeNormal;
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationController.navigationBar.hidden = YES;
  
  self.title = NSLocalizedString(@"friendmash", @"friendmash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
  [self setupStatsScroll];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Restore previously selected gameMode
  _gameMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedGameMode"] integerValue];
  [self setupGameMode];
  
  _isVisible = YES;
  
  // Start Stats Animation
  [self shouldStartStatsAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  _isVisible = NO;
  _isAnimating = NO;
  
  // Stop Stats Animation
  [self.statsLabel.layer removeAllAnimations];
  [self.statsNextLabel.layer removeAllAnimations];
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
  
  [self.statsView addSubview:self.statsLabel];
  [self.statsView addSubview:self.statsNextLabel];
}

- (void)shouldStartStatsAnimation {
  if (!_isAnimating) {
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
    self.statsLabel.text = [APP_DELEGATE.statsArray objectAtIndex:_statsCounter];
    _statsCounter++;
  }
  if (_statsCounter == [APP_DELEGATE.statsArray count]) _statsCounter = 0;
  self.statsNextLabel.text = [APP_DELEGATE.statsArray objectAtIndex:_statsCounter];
  if ([APP_DELEGATE.statsArray count] > 1) {
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
//  DLog(@"start stats scroll");
}

- (void)statsScrollFinished {
//  DLog(@"finished");
  if(_isVisible) {
    [self startStatsAnimation];
  }
}

- (IBAction)modeSelect:(UIButton *)modeButton {
  UIActionSheet *modeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose a Game Mode" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Show Friends", @"Show Social Network", @"Show Classmates", @"Show Everyone", nil];
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
      _gameMode = FriendmashGameModeFriends;
      [self.modeButton setTitle:@"Friends" forState:UIControlStateNormal];
      break;
    case 1:
      _gameMode = FriendmashGameModeNetwork;
      [self.modeButton setTitle:@"Social Network" forState:UIControlStateNormal];
      break;
    case 2:
      _gameMode = FriendmashGameModeSchool;
      [self.modeButton setTitle:@"Classmates" forState:UIControlStateNormal];
      break;
    case 3:
      _gameMode = FriendmashGameModeNormal;
      [self.modeButton setTitle:@"Everyone" forState:UIControlStateNormal];
      break;
    default:
      break;
  }
}

- (void)setupGameMode {
  switch (_gameMode) {
    case FriendmashGameModeFriends:
      [self.modeButton setTitle:@"Friends" forState:UIControlStateNormal];
      break;
    case FriendmashGameModeNetwork:
      [self.modeButton setTitle:@"Social Network" forState:UIControlStateNormal];
      break;
    case FriendmashGameModeSchool:
      [self.modeButton setTitle:@"Classmates" forState:UIControlStateNormal];
      break;
    case FriendmashGameModeNormal:
      [self.modeButton setTitle:@"Everyone" forState:UIControlStateNormal];
      break;
    default:
      break;
  }
}

- (IBAction)male {
  [self launchFriendmashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFriendmashWithGender:@"female"];
}

- (IBAction)about {
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
  RankingsViewController *rvc;
  if(isDeviceIPad()) {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPad" bundle:nil];
    rvc.modalPresentationStyle = UIModalPresentationFormSheet;
  } else {
    rvc = [[RankingsViewController alloc] initWithNibName:@"RankingsViewController_iPhone" bundle:nil];
  }
  rvc.launcherViewController = self;
//  rvc.gameMode = FriendmashGameModeNormal; // NOTE: force this to normal mode
  rvc.gameMode = _gameMode;
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
  fvc.mashCache.gender = gender;
  fvc.mashCache.gameMode = _gameMode;
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
  if (buttonIndex == 1) {
    [APP_DELEGATE logoutFacebook];
  }
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
  // IBOutlets
  RELEASE_SAFELY(_launcherView);
  RELEASE_SAFELY(_modeButton);
  RELEASE_SAFELY(_statsView);
  
  // IVARS
  RELEASE_SAFELY(_statsLabel);
  RELEASE_SAFELY(_statsNextLabel);
  
  [super dealloc];
}

@end
