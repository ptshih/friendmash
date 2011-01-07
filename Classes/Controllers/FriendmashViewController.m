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
#import "RemoteRequest.h"
#import "ThumbsView.h"
#import "OverlayView.h"
#import "LightboxViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "MashCache.h"

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
- (void)animateRotateRefresh;
- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate;
- (void)stopRotateRefresh;

- (void)setupViews;
- (void)loadLeftFaceView;
- (void)loadRightFaceView;

@end

@implementation FriendmashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;
@synthesize isLeftLoaded = _isLeftLoaded;
@synthesize isRightLoaded = _isRightLoaded;
@synthesize isTouchActive = _isTouchActive;
@synthesize resultsRequest = _resultsRequest;
@synthesize gender = _gender;
@synthesize leftUserId = _leftUserId;
@synthesize rightUserId = _rightUserId;
@synthesize gameMode = _gameMode;
@synthesize leftContainerView = _leftContainerView;
@synthesize rightContainerView = _rightContainerView;
@synthesize leftLoadingView = _leftLoadingView;
@synthesize rightLoadingView = _rightLoadingView;
@synthesize leftThumbsView = _leftThumbsView;
@synthesize rightThumbsView = _rightThumbsView;

@synthesize mashCache = _mashCache;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _gameMode = FriendmashGameModeNormal; // ALL game mode by default
    _isTouchActive = NO;
    _faceViewDidError = NO;
    
    [self setupViews];
    
    _mashCache = [[MashCache alloc] init];
    self.mashCache.delegate = self;
    _isMashLoaded = NO;
  }
  return self;
}

- (void)setupViews {
  // Faceview containers
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
  
  // Refresh rotating spinner views in top right
  if (isDeviceIPad()) {
    _refreshFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"btn_frame_iPad.png"]];
    _refreshSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"refresh_spinner_iPad.png"]];
  } else {
    _refreshFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"btn_frame.png"]];
    _refreshSpinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"refresh_spinner.png"]];
  }
  
  // Loading Views overlayed on top of faceview
  _leftLoadingView = [[[[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self options:nil] objectAtIndex:0] retain];
  self.leftLoadingView.layer.cornerRadius = 10.0;
  if (isDeviceIPad()) {
    self.leftLoadingView.frame = CGRectMake(180, 170, 80, 100);
  } else {
    self.leftLoadingView.frame = CGRectMake(60, 50, 80, 100);
  }
  
  _rightLoadingView = [[[[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:self options:nil] objectAtIndex:0] retain];
  self.rightLoadingView.layer.cornerRadius = 10.0;
  if (isDeviceIPad()) {
    self.rightLoadingView.frame = CGRectMake(180, 170, 80, 100);
  } else {
    self.rightLoadingView.frame = CGRectMake(60, 50, 80, 100);
  }
  
  // Thumbs Up/Down views
  _leftThumbsView = [[[[NSBundle mainBundle] loadNibNamed:@"ThumbsView" owner:self options:nil] objectAtIndex:0] retain];
  self.leftThumbsView.alpha = 0.0;
  if (isDeviceIPad()) {
    self.leftThumbsView.frame = CGRectMake(0, 0, 110, 100);
  }
  self.leftThumbsView.center = CGPointMake(self.leftContainerView.frame.size.width / 2, self.leftContainerView.frame.size.height / 2);
  
  _rightThumbsView = [[[[NSBundle mainBundle] loadNibNamed:@"ThumbsView" owner:self options:nil] objectAtIndex:0] retain];
  self.rightThumbsView.alpha = 0.0;
  if (isDeviceIPad()) {
    self.rightThumbsView.frame = CGRectMake(0, 0, 110, 100);
  }
  self.rightThumbsView.center = CGPointMake(self.rightContainerView.frame.size.width / 2, self.rightContainerView.frame.size.height / 2);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = NSLocalizedString(@"friendmash", @"friendmash");
  _toolbar.tintColor = RGBCOLOR(59,89,152);
  
  if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownHelp"]) {
    [self showHelp];
  }
  
  _refreshFrame.center = _remashButton.center;
  _refreshSpinner.center = _remashButton.center;
  _refreshFrame.hidden = YES;
  _refreshSpinner.hidden = YES;
  [self.view addSubview:_refreshFrame];
  [self.view addSubview:_refreshSpinner];
  [self.view addSubview:self.leftContainerView];
  [self.view addSubview:self.rightContainerView];
  [self.leftContainerView addSubview:self.leftLoadingView];
  [self.rightContainerView addSubview:self.rightLoadingView];
  [self.leftContainerView addSubview:self.leftThumbsView];
  [self.rightContainerView addSubview:self.rightThumbsView];
  

  // Start populating the cache
  [self.mashCache checkMashCache];
  [self prepareMash];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

#pragma mark Help Overlay
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
//  [FlurryAPI logEvent:@"friendmashRemash"];
  [self prepareMash];
}

- (void)prepareMash {
  [self animateRotateRefresh];
  _remashButton.hidden = YES;
  _refreshSpinner.hidden = NO;
  _refreshFrame.hidden = NO;
  _isLeftLoaded = NO;
  _isRightLoaded = NO;
  [self performSelectorOnMainThread:@selector(loadBothFaceViews) withObject:nil waitUntilDone:YES];
  
}
   
#pragma mark MashCacheDelegate
- (void)mashCacheNowHasData {
  if (_isMashLoaded) return; // If a mash is already loaded, don't load another
  
  // Retrieve a mash from cache
  NSDictionary *mash = [self.mashCache retrieveMashFromCache];
  // If mash is not nil, show it
  // Otherwise wait for the delegate callback telling us cache has data
  if (mash) {
    _isMashLoaded = YES;
    self.leftUserId = [mash objectForKey:@"leftUserId"];
    self.rightUserId = [mash objectForKey:@"rightUserId"];
    [self.leftView loadNewFaceWithImage:[mash objectForKey:@"leftImage"]];
    [self.rightView loadNewFaceWithImage:[mash objectForKey:@"rightImage"]];
  }
}
   
- (void)loadBothFaceViews {
  [self loadLeftFaceView];
  [self loadRightFaceView];

  // Retrieve a mash from cache
  NSDictionary *mash = [self.mashCache retrieveMashFromCache];
  // If mash is not nil, show it
  // Otherwise wait for the delegate callback telling us cache has data
  if (mash) {
    _isMashLoaded = YES;
    self.leftUserId = [mash objectForKey:@"leftUserId"];
    self.rightUserId = [mash objectForKey:@"rightUserId"];
    [self.leftView loadNewFaceWithImage:[mash objectForKey:@"leftImage"]];
    [self.rightView loadNewFaceWithImage:[mash objectForKey:@"rightImage"]];
  } else {
    _isMashLoaded = NO;
  }
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

#pragma mark FaceViewDelegate
- (BOOL)faceViewIsZoomed {
  if (self.modalViewController) {
    return YES;
  } else {
    return NO;
  }
}

- (void)faceViewDidZoom:(BOOL)isLeft withImage:(UIImage *)image {
  // Popup a lightbox view with full sized image
  LightboxViewController *lvc;
  if(isDeviceIPad()) {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPad" bundle:nil];
  } else {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPhone" bundle:nil];
  }
  lvc.facebookId = isLeft ? self.leftUserId : self.rightUserId;
  lvc.cachedImage = image;
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
    [self showLeftFaceView];
    [self showRightFaceView];
    _remashButton.hidden = NO;
    _refreshSpinner.hidden = YES;
    _refreshFrame.hidden = YES;
    [self stopRotateRefresh];
  }
  self.isTouchActive = NO;
}

- (void)faceViewDidSelect:(BOOL)isLeft {
  self.isTouchActive = YES;
  self.leftLoadingView.alpha = 0.0;
  self.rightLoadingView.alpha = 0.0;
  [self animateThumbsAndWinnerIsLeft:isLeft];
  if(isLeft) {
    [self animateFadeOutWithView:self.leftView withAlpha:1.0];
    [self animateFadeOutWithView:self.rightView withAlpha:0.4];
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.leftUserId andLoserId:self.rightUserId isLeft:isLeft withDelegate:self];
  } else {
    [self animateFadeOutWithView:self.leftView withAlpha:0.4];
    [self animateFadeOutWithView:self.rightView withAlpha:1.0];
    if(self.rightUserId && self.leftUserId) [self sendResultsRequestWithWinnerId:self.rightUserId andLoserId:self.leftUserId isLeft:isLeft withDelegate:self];
  }
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
  [UIView setAnimationDidStopSelector:@selector(animateThumbsFade)];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.4]; // Fade out is configurable in seconds (FLOAT)
  self.leftThumbsView.alpha = 1.0;
  self.rightThumbsView.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)animateThumbsFade {
  [UIView beginAnimations:@"ThumbsAnimationHide" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animateThumbsFinished)];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.leftThumbsView.alpha = 0.0;
  self.rightThumbsView.alpha = 0.0;
  [UIView commitAnimations];
}

- (void)animateThumbsFinished {
  [self prepareMash];
}

- (void)animateShowLoading {
  [self.leftContainerView bringSubviewToFront:self.leftLoadingView];
  [self.rightContainerView bringSubviewToFront:self.rightLoadingView];
  [UIView beginAnimations:@"ShowLoadingFadeIn" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];  
  [UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.leftLoadingView.alpha = 1.0;
  self.rightLoadingView.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)animateRotateRefresh {
  CABasicAnimation* rotationAnimation;
  rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
  rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
  rotationAnimation.duration = 1.0;
  rotationAnimation.cumulative = YES;
  rotationAnimation.repeatCount = INT_MAX;
  rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  
  [_refreshSpinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopRotateRefresh {
  [_refreshSpinner.layer removeAllAnimations];
}

#pragma mark Server Requests
- (void)sendResultsRequestWithWinnerId:(NSString *)winnerId andLoserId:(NSString *)loserId isLeft:(BOOL)isLeft withDelegate:(id)delegate {
  DLog(@"send results with winnerId: %@, loserId: %@, isLeft: %d",winnerId, loserId, isLeft);
  NSDictionary *postJson = [NSDictionary dictionaryWithObjectsAndKeys:winnerId, @"w", loserId, @"l", [NSNumber numberWithBool:isLeft], @"left", [NSNumber numberWithInteger:self.gameMode], @"mode", nil];
  NSData *postData = [[CJSONDataSerializer serializer] serializeDictionary:postJson];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/result/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  self.resultsRequest = [RemoteRequest postRequestWithBaseURLString:baseURLString andParams:nil andPostData:postData isGzip:NO withDelegate:nil];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // Use when fetching text data
  DLog(@"Raw response string from request: %@ => %@",request, [request responseString]);
  
  if([request isEqual:self.resultsRequest]) {
    DLog(@"send results request finished");
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Request Failed with Error: %@", [request error]);
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([alertView isEqual:_networkErrorAlert]) {
    switch (buttonIndex) {
      case 0:
        _remashButton.hidden = NO;
        _refreshSpinner.hidden = YES;
        _refreshFrame.hidden = YES;
        [self stopRotateRefresh];
        break;
      case 1:
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
  
  if(_gender) [_gender release];
  if(_leftUserId) [_leftUserId release];
  if(_rightUserId) [_rightUserId release];
  if(_toolbar) [_toolbar release];
  if(_remashButton) [_remashButton release];
  if(_refreshSpinner) [_refreshSpinner release];
  if(_refreshFrame) [_refreshFrame release];
  if(_leftContainerView) [_leftContainerView release];
  if(_rightContainerView) [_rightContainerView release];
  if(_leftView) [_leftView release];
  if(_rightView) [_rightView release];
  if(_leftLoadingView) [_leftLoadingView release];
  if(_rightLoadingView) [_rightLoadingView release];
  if(_leftThumbsView) [_leftThumbsView release];
  if(_rightThumbsView) [_rightThumbsView release];
  
  RELEASE_SAFELY(_mashCache);
  
  [super dealloc];
}

@end
