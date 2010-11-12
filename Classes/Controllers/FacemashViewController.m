//
//  FacemashViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashViewController.h"
#import "Constants.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"

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

- (void)sendMashRequestForLeftFaceViewWithDelegate:(id)delegate;
- (void)sendMashRequestForRightFaceViewWithDelegate:(id)delegate;
- (void)sendMashRequestForBothFaceViewsWithDelegate:(id)delegate;
- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate;

@end

@implementation FacemashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;
@synthesize isLeftLoaded = _isLeftLoaded;
@synthesize isRightLoaded = _isRightLoaded;
@synthesize networkQueue = _networkQueue;
@synthesize resultsRequest = _resultsRequest;
@synthesize leftRequest = _leftRequest;
@synthesize rightRequest = _rightRequest;
@synthesize bothRequest = _bothRequest;
@synthesize gender = _gender;
@synthesize leftUserId = _leftUserId;
@synthesize rightUserId = _rightUserId;
@synthesize gameMode = _gameMode;
@synthesize recentOpponentsArray = _recentOpponentsArray;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _shouldGoBack = NO;
    _leftUserId = nil;
    _rightUserId = nil;
    _gender = @"male"; // male by default
    _gameMode = FacemashGameModeNormal; // ALL game mode by default
    _isLeftLoaded = NO;
    _isRightLoaded = NO;;
    _recentOpponentsArray = [[NSMutableArray alloc] init];
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
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
  self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (IBAction)back {
  if(self.networkQueue.requestsCount == 0) {
    DLog(@"POP");
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    _shouldGoBack = YES;
    [self.networkQueue cancelAllOperations];
  }
}

- (IBAction)remash {
  _remashButton.enabled = NO;
  _isLeftLoaded = NO;
  _isRightLoaded = NO;
  [self.leftView removeFromSuperview];
  [self.rightView removeFromSuperview];
  [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
}

- (NSString *)getNewOpponentId {
#ifdef USE_OFFLINE_MODE
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
#else
  return nil;
#endif
}

- (void)prepareBothFaceViews {
  [self.leftView prepareFaceViewWithFacebookId:self.leftUserId];
  [self.rightView prepareFaceViewWithFacebookId:self.rightUserId];
}

- (void)prepareLeftFaceView {
  [self.leftView prepareFaceViewWithFacebookId:self.leftUserId];
}

- (void)prepareRightFaceView {

  [self.rightView prepareFaceViewWithFacebookId:self.rightUserId];
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
    self.leftView.frame = CGRectMake(48, 175, self.leftView.frame.size.width, self.leftView.frame.size.height);
  } else {
    self.leftView.frame = CGRectMake(20, 70, self.leftView.frame.size.width, self.leftView.frame.size.height);
  }
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
    self.rightView.frame = CGRectMake(536, 175, self.rightView.frame.size.width, self.rightView.frame.size.height);
  } else {
    self.rightView.frame = CGRectMake(250, 70, self.rightView.frame.size.width, self.rightView.frame.size.height);
  }
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
  if(!self.leftUserId && !self.rightUserId) {
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
  self.leftUserId = [self getNewOpponentId];
  [self prepareLeftFaceView];
#else
  if(self.leftUserId) [self.recentOpponentsArray addObject:self.leftUserId];
  if(self.rightUserId) [self sendMashRequestForLeftFaceViewWithDelegate:self];
#endif
}

- (void)loadAndShowRightFaceView {
  [self loadRightFaceView];
  [self showRightFaceView];
#ifdef USE_OFFLINE_MODE
  self.rightUserId = [self getNewOpponentId];
  [self prepareRightFaceView];
#else
  if(self.rightUserId) [self.recentOpponentsArray addObject:self.rightUserId];
  if(self.leftUserId) [self sendMashRequestForRightFaceViewWithDelegate:self];
#endif
}

- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self showLeftFaceView];
  [self loadRightFaceView];
  [self showRightFaceView];
#ifdef USE_OFFLINE_MODE
  self.leftUserId = [self getNewOpponentId];
  self.rightUserId = [self getNewOpponentId];
  [self prepareBothFaceViews];
#else
  if(self.leftUserId) [self.recentOpponentsArray addObject:self.leftUserId];
  if(self.rightUserId) [self.recentOpponentsArray addObject:self.rightUserId];
  [self sendMashRequestForBothFaceViewsWithDelegate:self];
#endif
}

#pragma mark FaceViewDelegate
- (void)faceViewDidFinishLoading:(BOOL)isLeft {
  if(isLeft) {
    _isLeftLoaded = YES;
  } else {
    _isRightLoaded = YES;
  }
  
  if(_isLeftLoaded && _isRightLoaded) _remashButton.enabled = YES;
}

- (void)faceViewWillAnimateOffScreen:(BOOL)isLeft {

}
- (void)faceViewDidAnimateOffScreen:(BOOL)isLeft {
#ifndef USE_OFFLINE_MODE
  if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.rightUserId andLoserId:self.leftUserId isLeft:isLeft withDelegate:self];
#endif
  [self remash];
}

- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate {
  NSDictionary *resultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:winnerId, @"w", loserId, @"l", [NSNumber numberWithBool:isLeft], @"left", nil];
  NSData *postData = [[CJSONDataSerializer serializer] serializeDictionary:resultDictionary];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/result/%@", FACEMASH_BASE_URL, [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  self.resultsRequest = [RemoteRequest postRequestWithBaseURLString:baseURLString andParams:nil andPostData:postData withDelegate:nil];
  [self.networkQueue addOperation:self.resultsRequest];
  [self.networkQueue go];
}

- (void)sendMashRequestForLeftFaceViewWithDelegate:(id)delegate {
//  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@",self.gender,[self.recentOpponentsArray componentsJoinedByString:@","]];
//  NSString *urlString = [NSString stringWithFormat:@"%@/mash/match/%@?%@", FACEMASH_BASE_URL, self.rightUserId, params];
}

- (void)sendMashRequestForRightFaceViewWithDelegate:(id)delegate {
//  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@",self.gender,[self.recentOpponentsArray componentsJoinedByString:@","]];
//  NSString *urlString = [NSString stringWithFormat:@"%@/mash/match/%@?%@", FACEMASH_BASE_URL, self.leftUserId, params];
}

- (void)sendMashRequestForBothFaceViewsWithDelegate:(id)delegate {
  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@&mode=%d", self.gender, [self.recentOpponentsArray componentsJoinedByString:@","], self.gameMode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/random/%@", FACEMASH_BASE_URL, [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  self.bothRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:self.bothRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // Use when fetching text data
  NSString *responseString = [request responseString];
  NSLog(@"Raw response string from request: %@ => %@",request, responseString);
  
  if([request isEqual:self.resultsRequest]) {
    DLog(@"send results request finished");
    
  } else if([request isEqual:self.leftRequest]) {
    
    DLog(@"left request finished");
    
    self.leftUserId = [request responseString];
    NSLog(@"Received match with leftId: %@", self.leftUserId);
    [self performSelectorOnMainThread:@selector(prepareLeftFaceView) withObject:nil waitUntilDone:YES];
    
  } else if([request isEqual:self.rightRequest]) {
    
    DLog(@"right request finished");
    
    self.rightUserId = [request responseString];
    NSLog(@"Received match with rightId: %@", self.rightUserId);
    [self performSelectorOnMainThread:@selector(prepareRightFaceView) withObject:nil waitUntilDone:YES];
    
  } else if([request isEqual:self.bothRequest]) {
    
    DLog(@"both request finished");
    NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];

    self.leftUserId = [responseArray objectAtIndex:0];
    self.rightUserId = [responseArray objectAtIndex:1];
    
    DLog(@"Received matches with leftId: %@ and rightId: %@", self.leftUserId, self.rightUserId);
    // protect against null IDs from failed server call
    if(!self.leftUserId || !self.rightUserId) {
      UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
      [networkErrorAlert show];
      [networkErrorAlert autorelease];
    } else {
      [self performSelectorOnMainThread:@selector(prepareBothFaceViews) withObject:nil waitUntilDone:YES];
    }
  }
  
  if(_shouldGoBack && self.networkQueue.requestsCount == 0) {
    DLog(@"POP QUEUE");
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  DLog(@"Request Failed with Error: %@", [request error]);

  UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
  [networkErrorAlert show];
  [networkErrorAlert autorelease];
  
//  if(_shouldGoBack && self.networkQueue.requestsCount == 0) {
//    DLog(@"POP QUEUE FROM ERROR");
//    [self.navigationController popViewControllerAnimated:YES];
//  }
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      [self sendMashRequestForBothFaceViewsWithDelegate:self];
      break;
    default:
      break;
  }
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
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  [_networkQueue release];
  [_recentOpponentsArray release];
  [_gender release];
  [_leftUserId release];
  [_rightUserId release];
  [super dealloc];
}

@end
