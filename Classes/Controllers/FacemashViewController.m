//
//  FacemashViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashViewController.h"
#import "Constants.h"

@interface FacemashViewController (Private)
- (void)loadLeftFaceView;
- (void)loadRightFaceView;
@end

@implementation FacemashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
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
  [self loadLeftFaceView];
  [self loadRightFaceView];
  self.title = NSLocalizedString(@"facemash", @"facemash");
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(fbLogout)];
  
  // Face View
  
  
  if([OBFacebookOAuthService isBound]) {
    [self.view addSubview:self.leftView];
    [self.view addSubview:self.rightView];  
  } else {
    [OBFacebookOAuthService bindWithDelegate:self andView:self.view];
  }
}

- (void)loadLeftFaceView {
  _leftView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
  self.leftView.canvas = self.view;
  self.leftView.isLeft = YES;
  self.leftView.delegate = self;
  self.leftView.frame = CGRectMake(40, 111, self.leftView.frame.size.width, self.leftView.frame.size.height);
  [self.leftView setDefaultPosition];
  
}

- (void)loadRightFaceView {
  _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
  self.rightView.canvas = self.view;
  self.rightView.isLeft = NO;
  self.rightView.delegate = self;
  self.rightView.frame = CGRectMake(532, 111, self.rightView.frame.size.width, self.rightView.frame.size.height);

  [self.rightView setDefaultPosition];
}

- (void)showLeftFaceView {
  self.leftView.alpha = 0.0;
  [self.view addSubview:self.leftView];
  [UIView beginAnimations:@"FaceViewFadeIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.25f]; // Fade out is configurable in seconds (FLOAT)
	self.leftView.alpha = 1.0f;
	[UIView commitAnimations];

}

- (void)showRightFaceView {
  self.rightView.alpha = 0.0;
  [self.view addSubview:self.rightView];
  [UIView beginAnimations:@"FaceViewFadeIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.25f]; // Fade out is configurable in seconds (FLOAT)
	self.rightView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)fbLogin {

}

- (void)fbLogout {
}

#pragma mark FaceViewDelegate
- (void)faceViewWillAnimateOffScreen:(FaceView *)faceView {

}
- (void)faceViewDidAnimateOffScreen:(FaceView *)faceView {
  if(faceView.isLeft) {
    [self loadLeftFaceView];
    [self showLeftFaceView];
  } else {
    [self loadRightFaceView];
    [self showRightFaceView];
  }
  [faceView removeFromSuperview];
}

#pragma mark OBOAuthServiceDelegate
- (void)oauthService:(Class)service didReceiveAccessToken:(OBOAuthToken *)accessToken {
  NSLog(@"Got access token:%@ with key: %@ and secret: %@", accessToken, accessToken.key, accessToken.secret);
  
  //store the token
  [OBOAuthToken persistTokens];
  [self performSelectorOnMainThread:@selector(dismissCredentialsView) withObject:nil waitUntilDone:YES];
}

- (void)dismissCredentialsView {
  if (self.modalViewController) {
    [self dismissModalViewControllerAnimated:YES];
  }
}

- (void)oauthService:(Class)service didFailToAuthenticateWithError:(NSError *)error {
  if ([[error domain] isEqualToString:OBOAuthServiceErrorDomain]) {
    if ([error code] == OBOAuthServiceErrorInvalidCredentials) {
      [self performSelectorOnMainThread:@selector(showBadCredentialsAlert) withObject:nil waitUntilDone:YES];
    }
  }
}

- (void)showBadCredentialsAlert {
  NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ Error", @"service error title format"), @"Facebook"];
  NSString *message = NSLocalizedString(@"Error authenticating, please check your credentials and try again.", @"error bad credentials");
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"ok button title") otherButtonTitles:nil] autorelease];
  [alert show];
}

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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [_leftView release];
  [_rightView release];
  [super dealloc];
}

@end
