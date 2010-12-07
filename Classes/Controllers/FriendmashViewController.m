//
//  FriendmashViewController.m
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "FriendmashViewController.h"
#import "Constants.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"
#import "ThumbsView.h"
#import "OverlayView.h"
#import "LightboxViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface FriendmashViewController (Private)

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

- (void)prepareMash;
- (void)showHelp;
- (void)loadBothFaceViews;
- (void)animateFadeOutWithView:(UIView *)theView withAlpha:(CGFloat)alpha;
- (void)animateThumbsAndWinnerIsLeft:(BOOL)isLeft;
- (void)animateThumbsFinished;
- (void)animateShowLoading;
- (void)sendMashRequestForBothFaceViewsWithDelegate:(id)delegate;
- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate;

@end

@implementation FriendmashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;
@synthesize isLeftLoaded = _isLeftLoaded;
@synthesize isRightLoaded = _isRightLoaded;
@synthesize isTouchActive = _isTouchActive;
@synthesize networkQueue = _networkQueue;
@synthesize resultsRequest = _resultsRequest;
@synthesize bothRequest = _bothRequest;
@synthesize gender = _gender;
@synthesize leftUserId = _leftUserId;
@synthesize rightUserId = _rightUserId;
@synthesize gameMode = _gameMode;
@synthesize recentOpponentsArray = _recentOpponentsArray;
@synthesize leftContainerView = _leftContainerView;
@synthesize rightContainerView = _rightContainerView;
@synthesize leftLoadingView = _leftLoadingView;
@synthesize rightLoadingView = _rightLoadingView;
@synthesize leftThumbsView = _leftThumbsView;
@synthesize rightThumbsView = _rightThumbsView;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _gameMode = FriendmashGameModeNormal; // ALL game mode by default
    _isLeftLoaded = NO;
    _isRightLoaded = NO;
    _isTouchActive = NO;
    _recentOpponentsArray = [[NSMutableArray alloc] init];
    _faceViewDidError = NO;
    
    if (isDeviceIPad()) {
      _leftContainerView = [[UIView alloc] initWithFrame:CGRectMake(48, 175, 440, 440)];
    } else {
      _leftContainerView = [[UIView alloc] initWithFrame:CGRectMake(25, 75, 200, 200)];
    }
    
    if (isDeviceIPad()) {
      _rightContainerView = [[UIView alloc] initWithFrame:CGRectMake(536, 175, 440, 440)];
    } else {
      _rightContainerView = [[UIView alloc] initWithFrame:CGRectMake(255, 75, 200, 200)];
    }
    
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
  
  [self.view addSubview:self.leftContainerView];
  [self.view addSubview:self.rightContainerView];
  _leftLoadingView = [[[[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self options:nil] objectAtIndex:0] retain];
  self.leftLoadingView.layer.cornerRadius = 10.0;
  if (isDeviceIPad()) {
    self.leftLoadingView.frame = CGRectMake(180, 170, 80, 100);
  } else {
    self.leftLoadingView.frame = CGRectMake(60, 50, 80, 100);
  }

  [self.leftContainerView addSubview:self.leftLoadingView];
  
  _rightLoadingView = [[[[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self options:nil] objectAtIndex:0] retain];
  self.rightLoadingView.layer.cornerRadius = 10.0;
  if (isDeviceIPad()) {
    self.rightLoadingView.frame = CGRectMake(180, 170, 80, 100);
  } else {
    self.rightLoadingView.frame = CGRectMake(60, 50, 80, 100);
  }
  [self.rightContainerView addSubview:self.rightLoadingView];
  
  // Thumbs Up/Down views
  _leftThumbsView = [[[[NSBundle mainBundle] loadNibNamed:@"ThumbsView" owner:self options:nil] objectAtIndex:0] retain];
  self.leftThumbsView.alpha = 0.0;
  if (isDeviceIPad()) {
    self.leftThumbsView.frame = CGRectMake(0, 0, 110, 100);
  }
  self.leftThumbsView.center = CGPointMake(self.leftContainerView.frame.size.width / 2, self.leftContainerView.frame.size.height / 2);
  [self.leftContainerView addSubview:self.leftThumbsView];

  _rightThumbsView = [[[[NSBundle mainBundle] loadNibNamed:@"ThumbsView" owner:self options:nil] objectAtIndex:0] retain];
  self.rightThumbsView.alpha = 0.0;
  if (isDeviceIPad()) {
    self.rightThumbsView.frame = CGRectMake(0, 0, 110, 100);
  }
  self.rightThumbsView.center = CGPointMake(self.rightContainerView.frame.size.width / 2, self.rightContainerView.frame.size.height / 2);
  [self.rightContainerView addSubview:self.rightThumbsView];
  
  [FlurryAPI logEvent:@"friendmashLoaded" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:self.gender, @"gender", [NSNumber numberWithInteger:self.gameMode], @"gameMode", nil]];
  
  self.title = NSLocalizedString(@"friendmash", @"friendmash");
  _toolbar.tintColor = RGBCOLOR(59,89,152);
  
  [self prepareMash];
  
  if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownHelp"]) {
    [self showHelp];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (IBAction)showHelp {
  if (isDeviceIPad()) {
    _helpView = [[[[NSBundle mainBundle] loadNibNamed:@"OverlayView_iPad" owner:self options:nil] objectAtIndex:0] retain];
  } else {
    _helpView = [[[[NSBundle mainBundle] loadNibNamed:@"OverlayView_iPhone" owner:self options:nil] objectAtIndex:0] retain];
  }
  [_helpView.dismissButton addTarget:self action:@selector(dismissHelp) forControlEvents:UIControlEventTouchUpInside];
  
  [self.view addSubview:_helpView];
}

- (void)dismissHelp {
  if(_helpView) {
    [_helpView removeFromSuperview];
    [_helpView release];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownHelp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (IBAction)back {
  [FlurryAPI logEvent:@"friendmashBack"];
  [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)remash {
  [self animateShowLoading];
  [self animateFadeOutWithView:self.leftView withAlpha:0.6];
  [self animateFadeOutWithView:self.rightView withAlpha:0.6];
  [self.leftContainerView bringSubviewToFront:self.leftLoadingView];
  [self.rightContainerView bringSubviewToFront:self.rightLoadingView];
  [FlurryAPI logEvent:@"friendmashRemash"];
  [self prepareMash];
}

- (void)prepareMash {
  _remashButton.enabled = NO;
  _isLeftLoaded = NO;
  _isRightLoaded = NO;
  [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
  
}

- (void)prepareBothFaceViews {
  [FlurryAPI logEvent:@"friendmashPreparedFaceViews" withParameters:[NSDictionary dictionaryWithObject:self.gender forKey:@"gender"]];
  [self.leftView prepareFaceViewWithFacebookId:self.leftUserId];
  [self.rightView prepareFaceViewWithFacebookId:self.rightUserId];
}

- (void)loadLeftFaceView {
  _tmpLeftView = self.leftView;
  if(isDeviceIPad()) {
    _leftView = [[[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPad" owner:self options:nil] objectAtIndex:0] retain];
  } else {
    _leftView = [[[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPhone" owner:self options:nil] objectAtIndex:0] retain];
  }

  self.leftView.friendmashViewController = self;
  self.leftView.canvas = self.view;
  self.leftView.toolbar = _toolbar;
  self.leftView.isLeft = YES;
  self.leftView.delegate = self;
}

- (void)loadRightFaceView {
  _tmpRightView = self.rightView;
  if(isDeviceIPad()) {
    _rightView = [[[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPad" owner:self options:nil] objectAtIndex:0] retain];
  } else {
    _rightView = [[[[NSBundle mainBundle] loadNibNamed:@"FaceView_iPhone" owner:self options:nil] objectAtIndex:0] retain];
  }
  
  self.rightView.friendmashViewController = self;
  self.rightView.canvas = self.view;
  self.rightView.toolbar = _toolbar;
  self.rightView.isLeft = NO;
  self.rightView.delegate = self;
}

- (void)showLeftFaceView {
  [UIView beginAnimations:@"LeftFlip" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.leftContainerView cache:YES];
	[UIView setAnimationDuration:0.25f]; // Fade out is configurable in seconds (FLOAT)
  [self.leftContainerView addSubview:self.leftView];
  self.leftLoadingView.alpha = 0.0;
  
  if(_tmpLeftView) {
    [_tmpLeftView removeFromSuperview];
  }

	[UIView commitAnimations];
  [_tmpLeftView release];
}

- (void)showRightFaceView {
  [UIView beginAnimations:@"RightFlip" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.rightContainerView cache:YES];
	[UIView setAnimationDuration:0.25f]; // Fade out is configurable in seconds (FLOAT)
  [self.rightContainerView addSubview:self.rightView];
  self.rightLoadingView.alpha = 0.0;

  if(_tmpRightView) {
    [_tmpRightView removeFromSuperview];
  }
	[UIView commitAnimations];
  [_tmpRightView release];
}

- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self loadRightFaceView];

  if(self.leftUserId) [self.recentOpponentsArray addObject:self.leftUserId];
  if(self.rightUserId) [self.recentOpponentsArray addObject:self.rightUserId];

  [self sendMashRequestForBothFaceViewsWithDelegate:self];
}

#pragma mark FaceViewDelegate
- (void)faceViewDidZoom:(BOOL)isLeft {
  // Popup a lightbox view with full sized image
  LightboxViewController *lvc;
  if(isDeviceIPad()) {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPad" bundle:nil];
  } else {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPhone" bundle:nil];
  }
  lvc.facebookId = isLeft ? self.leftUserId : self.rightUserId;
  [self presentModalViewController:lvc animated:YES];
  [lvc release];  
}

- (void)faceViewDidFinishLoading:(BOOL)isLeft {
  if(isLeft) {
    _isLeftLoaded = YES;
  } else {
    _isRightLoaded = YES;
  }
  
  if(_isLeftLoaded && _isRightLoaded) {
    [self animateThumbsFinished];
    [self showLeftFaceView];
    [self showRightFaceView];
    _remashButton.enabled = YES;
  }
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

- (void)faceViewDidSelect:(BOOL)isLeft {
  self.leftLoadingView.alpha = 0.0;
  self.rightLoadingView.alpha = 0.0;
  [self animateThumbsAndWinnerIsLeft:isLeft];
  if(isLeft) {
    [self animateFadeOutWithView:self.leftView withAlpha:0.6];
    [self animateFadeOutWithView:self.rightView withAlpha:0.6];
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.leftUserId andLoserId:self.rightUserId isLeft:isLeft withDelegate:self];
  } else {
    [self animateFadeOutWithView:self.leftView withAlpha:0.6];
    [self animateFadeOutWithView:self.rightView withAlpha:0.6];
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.rightUserId andLoserId:self.leftUserId isLeft:isLeft withDelegate:self];
  }
  
  [self prepareMash];
}

# pragma mark Animations
- (void)animateFadeOutWithView:(UIView *)theView withAlpha:(CGFloat)alpha {
  [UIView beginAnimations:@"FadeOutAlpha" context:nil];
  [UIView setAnimationDelegate:nil];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  theView.alpha = alpha;
  [UIView commitAnimations];
}

- (void)animateThumbsAndWinnerIsLeft:(BOOL)isLeft {
  if(isLeft) {
    [self.leftThumbsView setState:ThumbsLike];
    [self.rightThumbsView setState:ThumbsDislike];
  } else {
    [self.leftThumbsView setState:ThumbsDislike];
    [self.rightThumbsView setState:ThumbsLike];
  }

  [self.leftContainerView bringSubviewToFront:self.leftThumbsView];
  [self.rightContainerView bringSubviewToFront:self.rightThumbsView];
  
  [UIView beginAnimations:@"ThumbsAnimationShow" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animateThumbsHalfFinished)];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.5]; // Fade out is configurable in seconds (FLOAT)
  self.leftThumbsView.alpha = 1.0;
  self.rightThumbsView.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)animateThumbsHalfFinished {
  [UIView beginAnimations:@"ThumbsAnimationHide" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.4]; // Fade out is configurable in seconds (FLOAT)
  self.leftThumbsView.alpha = 0.4;
  self.rightThumbsView.alpha = 0.4;
  [UIView commitAnimations];
}

- (void)animateThumbsFinished {
  [UIView beginAnimations:@"ThumbsAnimationHide" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.leftThumbsView.alpha = 0.0;
  self.rightThumbsView.alpha = 0.0;
  [UIView commitAnimations];
}

- (void)animateShowLoading {
  [self.leftContainerView bringSubviewToFront:self.leftLoadingView];
  [self.rightContainerView bringSubviewToFront:self.rightLoadingView];
  [UIView beginAnimations:@"ShowLoadingFadeIn" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.6]; // Fade out is configurable in seconds (FLOAT)
  self.leftLoadingView.alpha = 1.0;
  self.rightLoadingView.alpha = 1.0;
  [UIView commitAnimations];
}

#pragma mark Server Requests
- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate {
  DLog(@"send results with winnerId: %@, loserId: %@, isLeft: %d",winnerId, loserId, isLeft);
  NSDictionary *postJson = [NSDictionary dictionaryWithObjectsAndKeys:winnerId, @"w", loserId, @"l", [NSNumber numberWithBool:isLeft], @"left", [NSNumber numberWithInteger:self.gameMode], @"mode", nil];
  NSData *postData = [[CJSONDataSerializer serializer] serializeDictionary:postJson];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/result/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.resultsRequest = [RemoteRequest postRequestWithBaseURLString:baseURLString andParams:nil andPostData:postData isGzip:NO withDelegate:nil];
  [self.networkQueue addOperation:self.resultsRequest];
  [self.networkQueue go];
}

- (void)sendMashRequestForBothFaceViewsWithDelegate:(id)delegate {
  // Add a 50 size limit to recents before clearing it.
  if([self.recentOpponentsArray count] >= 50) {
    [self.recentOpponentsArray removeAllObjects];
  }
  
  DLog(@"sending mash request for both face views");
  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@&mode=%d", self.gender, [self.recentOpponentsArray componentsJoinedByString:@","], self.gameMode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/random/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
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
      [FlurryAPI logEvent:@"errorFriendmashNoOpponents"];
      DLog(@"FMVC status code is 501 in request finished, response: %@", [request responseString]);
      _noContentAlert = [[UIAlertView alloc] initWithTitle:@"Oh Noes!" message:@"We ran out of mashes for you. Sending you back to the home screen so you can play again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
      [_noContentAlert show];
      [_noContentAlert autorelease];
    } else {
      [FlurryAPI logEvent:@"errorFriendmashNetworkError"];
      DLog(@"FMVC status code not 200 or 501 in request finished, response: %@", [request responseString]);
      _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
      [_networkErrorAlert show];
      [_networkErrorAlert autorelease];
    }
    return;
  }
  
  // Use when fetching text data
  DLog(@"Raw response string from request: %@ => %@",request, [request responseString]);
  
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

- (void)requestFailed:(ASIHTTPRequest *)request {
  [FlurryAPI logEvent:@"errorFriendmashRequestFailed"];
  DLog(@"Request Failed with Error: %@", [request error]);
  if(![request isEqual:self.resultsRequest]) {
    _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
    [_networkErrorAlert show];
    [_networkErrorAlert autorelease];
  }
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([alertView isEqual:_networkErrorAlert]) {
    switch (buttonIndex) {
      case 0:
        _remashButton.enabled = YES;
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
  if(_resultsRequest) {
    [_resultsRequest clearDelegatesAndCancel];
    [_resultsRequest release];
  }
  if(_bothRequest) {
    [_bothRequest clearDelegatesAndCancel];
    [_bothRequest release];
  }
  
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  
  if(_recentOpponentsArray) [_recentOpponentsArray release];
  if(_gender) [_gender release];
  if(_leftUserId) [_leftUserId release];
  if(_rightUserId) [_rightUserId release];
  if(_toolbar) [_toolbar release];
  if(_remashButton) [_remashButton release];
  if(_leftContainerView) [_leftContainerView release];
  if(_rightContainerView) [_rightContainerView release];
  if(_leftView) [_leftView release];
  if(_rightView) [_rightView release];
  if(_leftLoadingView) [_leftLoadingView release];
  if(_rightLoadingView) [_rightLoadingView release];
  if(_leftThumbsView) [_leftThumbsView release];
  if(_rightThumbsView) [_rightThumbsView release];
  [super dealloc];
}

@end
