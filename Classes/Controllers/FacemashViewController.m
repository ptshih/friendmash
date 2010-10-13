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
@synthesize isLeftLoaded = _isLeftLoaded;
@synthesize isRightLoaded = _isRightLoaded;
@synthesize resultsRequest = _resultsRequest;
@synthesize leftRequest = _leftRequest;
@synthesize rightRequest = _rightRequest;
@synthesize bothRequest = _bothRequest;
@synthesize gender = _gender;
@synthesize gameMode = _gameMode;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _leftUserId = nil;
    _rightUserId = nil;
    _gender = @"male"; // male by default
    _gameMode = FacemashGameModeNormal; // normal game mode by default
    _isLeftLoaded = NO;
    _isRightLoaded = NO;
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
  
//  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(fbLogout)];
//  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStyleBordered target:self action:@selector(testRequest)];
  
  [self loadAndShowFaceViews];
}

- (void)viewWillAppear:(BOOL)animated {
  self.navigationController.navigationBar.hidden = NO;
}

- (void)testRequest {
//  [OBFacebookOAuthService getCurrentUserWithDelegate:self];
//  _friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];
  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
  [OBFacemashClient getMashOpponentForId:[currentUserDictionary objectForKey:@"id"] withDelegate:self];
}

//- (IBAction)sendMashResults {
//  [OBFacemashClient postMashResultsForWinnerId:@"100000049912171" andLoserId:@"100000199684521" withDelegate:self];
//}
//
//- (IBAction)sendMashRequest {
//  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
//  [OBFacemashClient getMashOpponentForId:[[currentUserDictionary objectForKey:@"id"] stringValue] withDelegate:self];
//}
//
//- (IBAction)sendFriendsList {
//  NSDictionary *currentUserDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserDictionary"];
//  NSArray *friendsList = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
//  [OBFacemashClient postFriendsForFacebookId:[currentUserDictionary objectForKey:@"id"] withArray:friendsList withDelegate:self];
//}

/*
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
*/

- (NSString *)getNewOpponentId {
  NSArray *friendsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendsArray"];
  NSInteger count = [friendsArray count];
  float randomNum = arc4random() % count;
//  randomNum = 128; // testing a VERY LARGE ID
  
  if([[[friendsArray objectAtIndex:randomNum] objectForKey:@"gender"] isEqualToString:self.gender]) {
  
    NSLog(@"found opponent with id: %@ with name: %@",[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"], [[friendsArray objectAtIndex:randomNum] objectForKey:@"name"]);
//  return @"13710035";
    return [[friendsArray objectAtIndex:randomNum] objectForKey:@"id"];
  } else {
    return [self getNewOpponentId];
  }
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

  self.leftView.facemashViewController = self;
  self.leftView.canvas = self.view;
  self.leftView.toolbar = _toolbar;
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
  [self.leftView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] unsignedIntegerValue]];
   */
  
}

- (void)loadRightFaceView {
  if(isDeviceIPad()) {
    _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPad" owner:self options:nil] objectAtIndex:0];
  } else {
    _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPhone" owner:self options:nil] objectAtIndex:0];
  }
  
  self.rightView.facemashViewController = self;
  self.rightView.canvas = self.view;
  self.rightView.toolbar = _toolbar;
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
  
  [self.rightView prepareFaceViewWithFacebookId:[[[friendsArray objectAtIndex:randomNum] objectForKey:@"id"] unsignedIntegerValue]];
   */
}

- (void)showLeftFaceView {
  self.leftView.alpha = 0.0;
  [self.view insertSubview:self.leftView belowSubview:_toolbar];
//  [self.view addSubview:self.leftView];
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
  [self.view insertSubview:self.rightView belowSubview:_toolbar];
//  [self.view addSubview:self.rightView];
  [UIView beginAnimations:@"FaceViewFadeIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.25f]; // Fade out is configurable in seconds (FLOAT)
	self.rightView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)loadAndShowFaceViews {
  if(!_leftUserId && !_rightUserId) {
    [self loadBothFaceViews];
  } else {
    [self loadAndShowLeftFaceView];
    [self loadAndShowRightFaceView];
  }
}

- (void)loadAndShowLeftFaceView {
  [self loadLeftFaceView];
  [self showLeftFaceView];
#ifdef USE_OFFLINE_MODE
  _leftUserId = [self getNewOpponentId];
  [self prepareLeftFaceView];
#else
  if(_rightUserId > 0) self.leftRequest = [OBFacemashClient getMashOpponentForId:_rightUserId withDelegate:self];
#endif
}

- (void)loadAndShowRightFaceView {
  [self loadRightFaceView];
  [self showRightFaceView];
#ifdef USE_OFFLINE_MODE
  _rightUserId = [self getNewOpponentId];
  [self prepareRightFaceView];
#else
  if(_leftUserId > 0) self.rightRequest = [OBFacemashClient getMashOpponentForId:_leftUserId withDelegate:self];
#endif
}

- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self showLeftFaceView];
  [self loadRightFaceView];
  [self showRightFaceView];
#ifdef USE_OFFLINE_MODE
  _leftUserId = [self getNewOpponentId];
  _rightUserId = [self getNewOpponentId];
  [self prepareBothFaceViews];
#else
  self.bothRequest = [OBFacemashClient getInitialMashOpponentsWithDelegate:self];
#endif
}

#pragma mark FaceViewDelegate
- (void)faceViewDidFinishLoading:(BOOL)isLeft {
  if(isLeft) {
    _isLeftLoaded = YES;
  } else {
    _isRightLoaded = YES;
  }
}

- (void)faceViewWillAnimateOffScreen:(FaceView *)faceView {

}
- (void)faceViewDidAnimateOffScreen:(FaceView *)faceView {
  if(faceView.isLeft) {
#ifndef USE_OFFLINE_MODE
    if(_rightUserId && _leftUserId) self.resultsRequest = [OBFacemashClient postMashResultsForWinnerId:_rightUserId andLoserId:_leftUserId withDelegate:self];
#endif
    if(self.gameMode == FacemashGameModeNormal) {
      [self.leftView removeFromSuperview];
      [self performSelectorOnMainThread:@selector(loadAndShowLeftFaceView) withObject:nil waitUntilDone:YES];
    } else {
      [self.leftView removeFromSuperview];
      [self.rightView removeFromSuperview];
      [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
    }
    _isLeftLoaded = NO;
  } else {
#ifndef USE_OFFLINE_MODE
    if(_rightUserId && _leftUserId) self.resultsRequest = [OBFacemashClient postMashResultsForWinnerId:_leftUserId andLoserId:_rightUserId withDelegate:self];
#endif
    if(self.gameMode == FacemashGameModeNormal) {
      [self.rightView removeFromSuperview];
      [self performSelectorOnMainThread:@selector(loadAndShowRightFaceView) withObject:nil waitUntilDone:YES];
    } else {
      [self.leftView removeFromSuperview];
      [self.rightView removeFromSuperview];
      [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
    }
    _isRightLoaded = NO;
  }
}

#pragma mark OBClientOperationDelegate
- (void)obClientOperation:(OBClientOperation *)operation willSendRequest:(NSURLRequest *)request {
}

- (void)obClientOperation:(OBClientOperation *)operation failedToSendRequest:(NSURLRequest *)request withError:(NSError *)error {
}

- (void)obClientOperation:(OBClientOperation *)operation didProcessResponse:(OBClientResponse *)response {
  if ([operation.request isEqual:self.bothRequest]) {
    if([response isKindOfClass:[OBClientArrayResponse class]]) {
      OBClientArrayResponse *array = (OBClientArrayResponse *)response;
      
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      
      if (array.array.count == 2) {
        //we're in business
        OBFacebookUser *user1 = (OBFacebookUser *)[context objectWithID:[array.array objectAtIndex:0]];
        OBFacebookUser *user2 = (OBFacebookUser *)[context objectWithID:[array.array objectAtIndex:1]];
        
        _leftUserId = [user1.facebookId stringValue];
        _rightUserId = [user2.facebookId stringValue];
        [self performSelectorOnMainThread:@selector(prepareBothFaceViews) withObject:nil waitUntilDone:YES];
      }
      [context release];
    }
  } else if ([operation.request isEqual:self.leftRequest]) {
    if([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *object = (OBClientObjectResponse *)response;
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      NSError *error = nil;
      OBFacebookUser *user = (OBFacebookUser *)[context existingObjectWithID:object.entityID error:&error];
      if (error) {
        NSLog(@"Error getting user with id: %@, error: %@", object.entityID, error);
        
        //try again
        [context reset];
        error = nil;
        user = (OBFacebookUser *)[context existingObjectWithID:object.entityID error:&error];
        if (error) {
          NSLog(@"Tried twice to fetch a user, both times failed for object: %@, error: %@", object.entityID, error);
        }
      }
      _leftUserId = [user.facebookId stringValue];
      [context release];
      [self performSelectorOnMainThread:@selector(prepareLeftFaceView) withObject:nil waitUntilDone:YES];
    }
  } else if ([operation.request isEqual:self.rightRequest]) {
    if([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *object = (OBClientObjectResponse *)response;
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      NSError *error = nil;
      OBFacebookUser *user = (OBFacebookUser *)[context existingObjectWithID:object.entityID error:&error];
      if (error) {
        NSLog(@"Error getting user with id: %@, error: %@", object.entityID, error);
        
        //try again
        [context reset];
        error = nil;
        user = (OBFacebookUser *)[context existingObjectWithID:object.entityID error:&error];
        if (error) {
          NSLog(@"Tried twice to fetch a user, both times failed for object: %@, error: %@", object.entityID, error);
        }
      }
      _rightUserId = [user.facebookId stringValue];
      [context release];
      [self performSelectorOnMainThread:@selector(prepareRightFaceView) withObject:nil waitUntilDone:YES];
    }
  }
}

- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request {
}

- (void)obClientOperation:(OBClientOperation *)operation didFinishRequest:(NSURLRequest *)request {
}

- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request whichFailedWithError:(NSError *)error {

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
  [_gender release];
  [super dealloc];
}

@end
