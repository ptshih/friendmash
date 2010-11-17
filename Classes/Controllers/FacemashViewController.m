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

/**
 Load and Show just performs the load method and then animates an addToSubview
 */

- (void)loadBothFaceViews;

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
    _gameMode = FacemashGameModeNormal; // ALL game mode by default
    _isLeftLoaded = NO;
    _isRightLoaded = NO;
    _recentOpponentsArray = [[NSMutableArray alloc] init];
    _networkQueue = [[ASINetworkQueue queue] retain];
    _faceViewDidError = NO;
    
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
  
  self.title = NSLocalizedString(@"facemash", @"facemash");
  _toolbar.tintColor = RGBCOLOR(59,89,152);
  
  [self remash];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (IBAction)back {
  [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)remash {
  _remashButton.enabled = NO;
  _isLeftLoaded = NO;
  _isRightLoaded = NO;
  [self.leftView removeFromSuperview];
  [self.rightView removeFromSuperview];
  [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
}

- (void)prepareBothFaceViews {
  [self.leftView prepareFaceViewWithFacebookId:self.leftUserId];
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

- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self showLeftFaceView];
  [self loadRightFaceView];
  [self showRightFaceView];

  // Don't add to recents if this is an ad
  NSString *adFlagLeft = [self.leftUserId substringToIndex:5];
  NSString *adFlagRight = [self.rightUserId substringToIndex:5];
  if(![adFlagLeft isEqualToString:@"fmad_"] && ![adFlagRight isEqualToString:@"fmad_"]) {
    if(self.leftUserId) [self.recentOpponentsArray addObject:self.leftUserId];
    if(self.rightUserId) [self.recentOpponentsArray addObject:self.rightUserId];
  }

  [self sendMashRequestForBothFaceViewsWithDelegate:self];
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

- (void)faceViewDidFailWithError:(NSDictionary *)errorDict {
  if(_faceViewDidError) return;
  _faceViewDidError = YES;
  _oauthErrorAlert = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Your Facebook session has expired. Please login to Facebook again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [_oauthErrorAlert show];
  [_oauthErrorAlert autorelease];
}

- (void)faceViewDidFailPictureDoesNotExist {
  if(_faceViewDidError) return;
  _faceViewDidError = YES;
  _fbPictureErrorAlert = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Facebook encountered an error, we promise it isn't our fault! Please try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [_fbPictureErrorAlert show];
  [_fbPictureErrorAlert autorelease];  
}

- (void)faceViewWillAnimateOffScreen:(BOOL)isLeft {

}

- (void)faceViewDidAnimateOffScreen:(BOOL)isLeft {
  if(isLeft) {
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.rightUserId andLoserId:self.leftUserId isLeft:isLeft withDelegate:self];
  } else {
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.leftUserId andLoserId:self.rightUserId isLeft:isLeft withDelegate:self];
  }

  [self remash];
}

- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate {
  BOOL isAd = NO;
  NSString *adFlagLeft = [self.leftUserId substringToIndex:5];
  NSString *adFlagRight = [self.rightUserId substringToIndex:5];
  if([adFlagLeft isEqualToString:@"fmad_"] && [adFlagRight isEqualToString:@"fmad_"]) {
    isAd = YES;
  }
  
  DLog(@"send results with winnerId: %@, loserId: %@, isLeft: %d, isAd: %d",winnerId, loserId, isLeft, isAd);
  NSString *params = [NSString stringWithFormat:@"w=%@&l=%@&left=%d&mode=%d&ad=%d", winnerId, loserId, isLeft, self.gameMode, isAd];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/result/%@", FACEMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.resultsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:self.resultsRequest];
  [self.networkQueue go];
}

- (void)sendMashRequestForBothFaceViewsWithDelegate:(id)delegate {
  DLog(@"sending mash request for both face views");
  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@&mode=%d", self.gender, [self.recentOpponentsArray componentsJoinedByString:@","], self.gameMode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/random/%@", FACEMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.bothRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:self.bothRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    DLog(@"FMVC status code not 200 in request finished, response: %@", [request responseString]);
    // Check for a not-implemented (did not find opponents) response
    if(statusCode == 501) {
      DLog(@"FMVC status code is 501 in request finished, response: %@", [request responseString]);
      _noContentAlert = [[UIAlertView alloc] initWithTitle:@"Oh Noes!" message:@"We ran out of mashes for you. Sending you back to the home screen so you can play again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
      [_noContentAlert show];
      [_noContentAlert autorelease];
    } else {
      DLog(@"FMVC status code not 200 or 501 in request finished, response: %@", [request responseString]);
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
    }
    return;
  }
  
  // Use when fetching text data
  NSString *responseString = [request responseString];
  DLog(@"Raw response string from request: %@ => %@",request, responseString);
  
  if([request isEqual:self.resultsRequest]) {
    DLog(@"send results request finished");
    
  } else if([request isEqual:self.bothRequest]) {
    DLog(@"both request finished");
    NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];

    self.leftUserId = [responseArray objectAtIndex:0];
    self.rightUserId = [responseArray objectAtIndex:1];
    
    DLog(@"Received matches with leftId: %@ and rightId: %@", self.leftUserId, self.rightUserId);
    // protect against null IDs from failed server call
    if(!self.leftUserId || !self.rightUserId) {
      DLog(@"FMVC left or right userId is null, left: %@, right: %@, response: %@", self.leftUserId, self.rightUserId, [request responseString]);
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
    } else {
      [self performSelectorOnMainThread:@selector(prepareBothFaceViews) withObject:nil waitUntilDone:YES];
    }
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  DLog(@"Request Failed with Error: %@", [request error]);

  _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
  [_networkErrorAlert show];
  [_networkErrorAlert autorelease];
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([alertView isEqual:_networkErrorAlert]) {
    switch (buttonIndex) {
      case 0:
        break;
      case 1:
        [self sendMashRequestForBothFaceViewsWithDelegate:self];
        break;
      default:
        break;
    }
  } else if([alertView isEqual:_noContentAlert]) {
    [self.navigationController popViewControllerAnimated:YES];
  } else if([alertView isEqual:_oauthErrorAlert]) {
    _faceViewDidError = NO;
    [self.navigationController popViewControllerAnimated:NO];
    [APP_DELEGATE fbDidLogout];
  } else if([alertView isEqual:_fbPictureErrorAlert]) {
    _faceViewDidError = NO;
    [self.navigationController popViewControllerAnimated:NO];
  }
}

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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  if(_recentOpponentsArray) [_recentOpponentsArray release];
  if(_gender) [_gender release];
  if(_leftUserId) [_leftUserId release];
  if(_rightUserId) [_rightUserId release];
  if(_resultsRequest) [_resultsRequest release];
  if(_bothRequest) [_bothRequest release];
  if(_toolbar) [_toolbar release];
  if(_remashButton) [_remashButton release];
  [super dealloc];
}

@end
