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
#import "AboutViewController.h"
#import "Constants.h"

@interface LauncherViewController (Private)

/**
 This method creates and pushes the FacemashViewController and sets it's iVar to the designated gender
 */
- (void)launchFacemashWithGender:(NSString *)gender;

@end

@implementation LauncherViewController

@synthesize launcherView = _launcherView;
@synthesize splashView = _splashView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationController.navigationBar.hidden = YES;
  
  self.title = NSLocalizedString(@"facemash", @"facemash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  self.navigationController.navigationBar.hidden = YES;
}

- (IBAction)male {
  [self launchFacemashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFacemashWithGender:@"female"];
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
  if(_launcherView) [_launcherView release];
  if(_gameModeSwitch) [_gameModeSwitch release];
  if(_splashView) [_splashView release];
  [super dealloc];
}

@end
