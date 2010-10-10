//
//  FacemashViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashViewController.h"
#import "Constants.h"
#import "OBFacemashClient.h"
#import "CJSONDeserializer.h"

@interface FacemashViewController (Private)
/**
 This method checks to see if an OAuth token exists for FB.
 If a token exists, we are already bound and will load, position, and display the left/right faceViews.
 Also send a request to get an NSDictionary of the current user and store it in userDefaults.
 If a token does not exist, remove left/right views from superview and perform FB authorization.
 */
- (void)checkFBAuthAndGetCurrentUser;
/**
 Loads a FaceView from NIB and configures:
 canvas - this is our current frame
 delegate - our own view controller
 isLeft - is this faceView left or right
 frame - position it appropriately on the screen/canvas
 
 Also calls [FaceView setDefaultPosition] this sets an iVar inside FaceView to it's current center position
 */
- (void)loadLeftFaceView;
- (void)loadRightFaceView;
/**
 Load and Show just performs the load method and then animates an addToSubview
 */
- (void)loadAndShowLeftFaceView;
- (void)loadAndShowRightFaceView;
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
  
  self.title = NSLocalizedString(@"facemash", @"facemash");
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(fbLogout)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStyleBordered target:self action:@selector(testRequest)];
  
  // Check token and authorize
  [self checkFBAuthAndGetCurrentUser];
}

- (void)testRequest {
//  [OBFacebookOAuthService getCurrentUserWithDelegate:self];
//  _friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];
  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
  [OBFacemashClient getMashOpponentForId:[[currentUserDictionary objectForKey:@"id"] intValue] withDelegate:self];
}

- (IBAction)sendMashResults {
  [OBFacemashClient postMashResultsForWinnerId:1 andLoserId:2 withDelegate:self];
}

- (IBAction)sendMashRequest {
  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
  [OBFacemashClient getMashOpponentForId:[[currentUserDictionary objectForKey:@"id"] intValue] withDelegate:self];
}

- (IBAction)sendFriendsList {
  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
  NSArray *friendsList = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  [OBFacemashClient postFriendsForFacebookId:[[currentUserDictionary objectForKey:@"id"] intValue] withArray:friendsList withDelegate:self];
}

- (void)checkFBAuthAndGetCurrentUser {
  if([OBFacebookOAuthService isBound]) {
    _currentUserRequest = [OBFacebookOAuthService getCurrentUserWithDelegate:self];
    _friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];
    [self loadAndShowLeftFaceView];
    [self loadAndShowRightFaceView];
  } else {
    if(_leftView) [self.leftView removeFromSuperview];
    if(_rightView) [self.rightView removeFromSuperview];
    [OBFacebookOAuthService bindWithDelegate:self andView:self.view];
  } 
}

- (UIImage *)getNewOpponent {
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  if(!friendsArray) return [UIImage imageNamed:@"mrt_profile.jpg"];
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
  NSLog(@"rand: %g",randomNum);
  NSString *graphUrl = [NSString stringWithFormat:@"https:/graph.facebook.com/%@/picture?type=large",[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"]];
  return [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:graphUrl]]];
}

- (void)loadLeftFaceView {
  _leftView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
//  self.leftView.faceImageView.image = [UIImage imageNamed:@"mrt_profile.jpg"];
  self.leftView.canvas = self.view;
  self.leftView.isLeft = YES;
  self.leftView.delegate = self;
  self.leftView.frame = CGRectMake(40, 111, self.leftView.frame.size.width, self.leftView.frame.size.height);
  
  // Temp random
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  if (friendsArray == nil) {
    return;
  }
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
  NSLog(@"rand: %g",randomNum);
  [self.leftView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] intValue]];
  
}

- (void)loadRightFaceView {
  _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
  self.rightView.canvas = self.view;
  self.rightView.isLeft = NO;
  self.rightView.delegate = self;
  self.rightView.frame = CGRectMake(532, 111, self.rightView.frame.size.width, self.rightView.frame.size.height);

  // Temp random
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  if (friendsArray == nil) {
    return;
  }
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
  NSLog(@"rand: %g",randomNum);
  [self.rightView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] intValue]];
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

- (void)loadAndShowLeftFaceView {
  [self loadLeftFaceView];
  [self showLeftFaceView];
}

- (void)loadAndShowRightFaceView {
  [self loadRightFaceView];
  [self showRightFaceView];
}

- (void)fbLogin {

}

- (void)fbLogout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      break;
    case 1:
      [OBFacebookOAuthService unbindWithDelegate:self];
      break;
    default:
      break;
  }
}

#pragma mark FaceViewDelegate
- (void)faceViewWillAnimateOffScreen:(FaceView *)faceView {

}
- (void)faceViewDidAnimateOffScreen:(FaceView *)faceView {
  if(faceView.isLeft) {
    [self performSelectorOnMainThread:@selector(loadAndShowLeftFaceView) withObject:nil waitUntilDone:YES];
  } else {
    [self performSelectorOnMainThread:@selector(loadAndShowRightFaceView) withObject:nil waitUntilDone:YES];
  }
  [faceView removeFromSuperview];
}

#pragma mark OBClientOperationDelegate
- (void)obClientOperation:(OBClientOperation *)operation willSendRequest:(NSURLRequest *)request {
}

/*!
 Called when the operation fails to send the request, with the error object returned from NSURLConnection
 */
- (void)obClientOperation:(OBClientOperation *)operation failedToSendRequest:(NSURLRequest *)request withError:(NSError *)error {
}

/*!
 Called immediately after the request is sent if it is successful, i.e. hasOKHTTPResponse returns YES.
 */
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request {
  if(request == _currentUserRequest) {
    // Set the current user's info locally
//    NSString *currentUserResponse = [[NSString alloc] initWithData:[operation responseData] encoding:NSUTF8StringEncoding];
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[operation responseData] error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:responseDict forKey:@"currentUserDictionary"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  } else if(request == _friendsRequest) {
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[operation responseData] error:nil];
    NSArray *responseArray = [responseDict objectForKey:@"data"];
    [[NSUserDefaults standardUserDefaults] setObject:responseArray forKey:@"friendsArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    NSLog(@"res: %@",[responseDict objectForKey:@"data"]);
  } else {
    NSString *response = [[NSString alloc] initWithData:[operation responseData] encoding:NSUTF8StringEncoding];
    NSLog(@"Facemash string response: %@",response);
  }


}

/*!
 Called after the request has finished processing.  That is if the request is an OBClientRequest and a valid OBClientResponse object
 is returned the operation automatically invokes processResponseData on the response object and upon completion calls this delegate method.
 
 This is the last stage in the request / response loop after which the operation will be popped out of the NSOperationQueue and deallocated.
 */
- (void)obClientOperation:(OBClientOperation *)operation didFinishRequest:(NSURLRequest *)request {
}

/*!
 Called when the request completes but hasOKHTTPResponse returns NO.
 */
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request whichFailedWithError:(NSError *)error {

}

#pragma mark OBOAuthServiceDelegate
- (void)oauthService:(Class)service didReceiveAccessToken:(OBOAuthToken *)accessToken {
  NSLog(@"Got access token:%@ with key: %@ and secret: %@", accessToken, accessToken.key, accessToken.secret);
  
  //store the token
  [OBOAuthToken persistTokens];
  [self checkFBAuthAndGetCurrentUser];
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

- (void)oauthServiceDidUnbind:(Class)service {
  [self checkFBAuthAndGetCurrentUser];
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
