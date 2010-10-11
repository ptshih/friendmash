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
#import "OBCoreDataStack.h"

@interface FacemashViewController (Private)

/**
 Initiate a bind with Facebook for OAuth token
 */
- (void)bindWithFacebook;

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
- (void)loadAndShowFaceViews;
- (void)loadBothFaceViews;
@end

@implementation FacemashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;
@synthesize currentUserRequest = _currentUserRequest;
@synthesize friendsRequest = _friendsRequest;
@synthesize resultsRequest = _resultsRequest;
@synthesize leftRequest = _leftRequest;
@synthesize rightRequest = _rightRequest;
@synthesize bothRequest = _bothRequest;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _leftUserId = 0;
    _rightUserId = 0;
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
  _toolbar.tintColor = RGBCOLOR(59,89,152);
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(fbLogout)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStyleBordered target:self action:@selector(testRequest)];
  
  // Check token and authorize
  [self bindWithFacebook];
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

- (void)bindWithFacebook {
  [OBFacebookOAuthService bindWithDelegate:self andView:self.view]; 
}

- (void)checkFBAuthAndGetCurrentUser {
  if([OBFacebookOAuthService isBound]) {
    self.currentUserRequest = [OBFacebookOAuthService getCurrentUserWithDelegate:self];
    self.friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];
    [self loadAndShowFaceViews];
  } else {
    if(_leftView) [self.leftView removeFromSuperview];
    if(_rightView) [self.rightView removeFromSuperview];
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

- (void)prepareBothFaceViews {
    [self.leftView prepareFaceViewWithFacebookId:_leftUserId];
    [self.rightView prepareFaceViewWithFacebookId:_rightUserId];
}

- (void)prepareLeftFaceView {
  [self.leftView prepareFaceViewWithFacebookId:_leftUserId];
}

- (void)prepareRightFaceView {

  [self.rightView prepareFaceViewWithFacebookId:_rightUserId];
}

- (void)loadLeftFaceView {
  if(isDeviceIPad()) {
    _leftView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPad" owner:self options:nil] objectAtIndex:0];
  } else {
    _leftView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPhone" owner:self options:nil] objectAtIndex:0];
  }

  self.leftView.canvas = self.view;
  self.leftView.isLeft = YES;
  self.leftView.delegate = self;
  if(isDeviceIPad()) {
    self.leftView.frame = CGRectMake(48, 111, self.leftView.frame.size.width, self.leftView.frame.size.height);
  } else {
    self.leftView.frame = CGRectMake(20, 6, self.leftView.frame.size.width, self.leftView.frame.size.height);
  }
  
  // Temp random
  /*
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  if (friendsArray == nil) {
    return;
  }
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
  NSLog(@"rand: %g",randomNum);
  [self.leftView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] intValue]];
   */
  
}

- (void)loadRightFaceView {
  if(isDeviceIPad()) {
    _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPad" owner:self options:nil] objectAtIndex:0];
  } else {
    _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPhone" owner:self options:nil] objectAtIndex:0];
  }

  self.rightView.canvas = self.view;
  self.rightView.isLeft = NO;
  self.rightView.delegate = self;
  if(isDeviceIPad()) {
    self.rightView.frame = CGRectMake(536, 111, self.rightView.frame.size.width, self.rightView.frame.size.height);
  } else {
    self.rightView.frame = CGRectMake(250, 6, self.rightView.frame.size.width, self.rightView.frame.size.height);
  }

  // Temp random
  /*
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  if (friendsArray == nil) {
    return;
  }
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
  NSLog(@"rand: %g",randomNum);
  
  [self.rightView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] intValue]];
   */
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

- (void)loadAndShowFaceViews {
  if(_leftUserId == 0 && _rightUserId == 0) {
    [self loadBothFaceViews];
  } else {
    [self loadAndShowLeftFaceView];
    [self loadAndShowRightFaceView];
  }
}

- (void)loadAndShowLeftFaceView {
  [self loadLeftFaceView];
  [self showLeftFaceView];
  self.leftRequest = [OBFacemashClient getMashOpponentForId:_rightUserId withDelegate:self];
}

- (void)loadAndShowRightFaceView {
  [self loadRightFaceView];
  [self showRightFaceView];
  self.rightRequest = [OBFacemashClient getMashOpponentForId:_leftUserId withDelegate:self];
}

- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self showLeftFaceView];
  [self loadRightFaceView];
  [self showRightFaceView];
  self.bothRequest = [OBFacemashClient getInitialMashOpponentsWithDelegate:self];
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
      if(_leftView) [self.leftView removeFromSuperview];
      if(_rightView) [self.rightView removeFromSuperview];
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
    self.resultsRequest = [OBFacemashClient postMashResultsForWinnerId:_rightUserId andLoserId:_leftUserId withDelegate:self];
    [self performSelectorOnMainThread:@selector(loadAndShowLeftFaceView) withObject:nil waitUntilDone:YES];
  } else {
    self.resultsRequest = [OBFacemashClient postMashResultsForWinnerId:_leftUserId andLoserId:_rightUserId withDelegate:self];
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

- (void)obClientOperation:(OBClientOperation *)operation didProcessResponse:(OBClientResponse *)response {
  if ([operation.request isEqual:self.currentUserRequest]) {
    //this should be an object response
    if ([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *obj = (OBClientObjectResponse *)response;
      
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      OBFacebookUser *user = (OBFacebookUser *)[context objectWithID:obj.entityID];
      
      [OBFacemashClient postUser:user withDelegate:self];
      
      [[NSUserDefaults standardUserDefaults] setObject:user.facebookId forKey:@"currentUserId"];
    } else {
      NSLog(@"Got the wrong response back for the current user request, should be an object response but was: %@", response);
    }
  } else if ([operation.request isEqual:self.friendsRequest]) {
    //this operation should be a collection response
    if ([response isKindOfClass:[OBClientCollectionResponse class]]) {
      OBClientCollectionResponse *collection = (OBClientCollectionResponse *)response;
      
      //send the friends list up to the server
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      
      NSMutableArray *friends = [NSMutableArray array];
      for (NSManagedObjectID *objectID in collection.list) {
        NSManagedObject *obj = [context objectWithID:objectID];
        if (obj) {
          [friends addObject:obj];
        }
      }
      
      //send the friends
      NSNumber *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"];
      [OBFacemashClient postFriendsForFacebookId:[facebookId intValue] withArray:friends withDelegate:self];
    }
  } else if ([operation.request isEqual:self.bothRequest]) {
    if([response isKindOfClass:[OBClientArrayResponse class]]) {
      OBClientArrayResponse *array = (OBClientArrayResponse *)response;
      
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      
      if (array.array.count == 2) {
        //we're in business
        OBFacebookUser *user1 = (OBFacebookUser *)[context objectWithID:[array.array objectAtIndex:0]];
        OBFacebookUser *user2 = (OBFacebookUser *)[context objectWithID:[array.array objectAtIndex:1]];
        
        _leftUserId = [user1.facebookId intValue];
        _rightUserId = [user2.facebookId intValue];
        [self performSelectorOnMainThread:@selector(prepareBothFaceViews) withObject:nil waitUntilDone:YES];
      }
    }
  } else if ([operation.request isEqual:self.leftRequest]) {
    if([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *object = (OBClientObjectResponse *)response;
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      OBFacebookUser *user = (OBFacebookUser *)[context objectWithID:object.entityID];
      _leftUserId = [user.facebookId intValue];
      [self performSelectorOnMainThread:@selector(prepareLeftFaceView) withObject:nil waitUntilDone:YES];
    }
  } else if ([operation.request isEqual:self.rightRequest]) {
    if([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *object = (OBClientObjectResponse *)response;
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      OBFacebookUser *user = (OBFacebookUser *)[context objectWithID:object.entityID];
      _rightUserId = [user.facebookId intValue];
      [self performSelectorOnMainThread:@selector(prepareRightFaceView) withObject:nil waitUntilDone:YES];
    }
  }
}

/*!
 Called immediately after the request is sent if it is successful, i.e. hasOKHTTPResponse returns YES.
 */
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request {
  if(request == self.currentUserRequest) {
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
//    NSLog(@"res: %@",[responseDict objectForKey:@"data"]);
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
  [self bindWithFacebook];
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
