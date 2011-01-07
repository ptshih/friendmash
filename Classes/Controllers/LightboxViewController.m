//
//  LightboxViewController.m
//  Friendmash
//
//  Created by Peter Shih on 11/16/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "LightboxViewController.h"
#import "Constants.h"
#import "ASIHTTPRequest.h"
#import "RemoteRequest.h"
#import "RemoteOperation.h"
#import "ImageManipulator.h"

@interface LightboxViewController (Private)
- (void)createGestureRecognizers;
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void)loadCachedImage;
- (void)getProfilePicture;
@end

@implementation LightboxViewController

@synthesize cachedImage = _cachedImage;
@synthesize facebookId = _facebookId;
@synthesize pictureRequest = _pictureRequest;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _facebookId = [[NSString alloc] init];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self createGestureRecognizers];
  if (self.cachedImage) {
    [self loadCachedImage];
  } else {
    [self getProfilePicture];
  }
}

- (void)createGestureRecognizers {
  UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  doubleTap.numberOfTapsRequired = 2;
  doubleTap.delegate = self;
  [self.view addGestureRecognizer:doubleTap];
  [doubleTap release];
  
  UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
  pinchGesture.delegate = self;
  [_profileImageView addGestureRecognizer:pinchGesture];
  [pinchGesture release];
  
  UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
  panGesture.maximumNumberOfTouches = 2;
  [_profileImageView addGestureRecognizer:panGesture];
  [panGesture release];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
  DLog(@"detected tap gesture with state: %d", [sender state]);
  if (sender.state == UIGestureRecognizerStateBegan) {
  } else if (sender.state == UIGestureRecognizerStateEnded) {
    [self dismiss];
  }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer {
  DLog(@"detected pinch gesture with state: %d with scale: %f", [gestureRecognizer state], [gestureRecognizer scale]);
  [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
  DLog(@"transform: %f %f", gestureRecognizer.view.transform.a, gestureRecognizer.view.transform.d);
  if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
    if (gestureRecognizer.view.transform.a < 0.85 || gestureRecognizer.view.transform.d < 0.85) {
      [self dismiss];
    } else {
      [gestureRecognizer view].transform = CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
      [gestureRecognizer setScale:1];
    }
  }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
  UIView *piece = [gestureRecognizer view];
  
  [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
  
  if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:[piece superview]];
    
    [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y + translation.y)];
    [gestureRecognizer setTranslation:CGPointZero inView:[piece superview]];
  }
}

// scale and rotation transforms are applied relative to the layer's anchor point
// this method moves a gesture recognizer's view's anchor point between the user's fingers
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    UIView *piece = gestureRecognizer.view;
    CGPoint locationInView = [gestureRecognizer locationInView:piece];
    CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
    
    piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
    piece.center = locationInSuperview;
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (IBAction)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)loadCachedImage {
  _profileImageView.image = self.cachedImage;
  _profileImageView.backgroundColor = [UIColor clearColor];
  [_activityIndicator stopAnimating];
}

- (void)getProfilePicture {
  self.pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.facebookId andType:@"large" withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.pictureRequest];
}

- (void)loadNewFaceWithData:(UIImage *)faceImage {
  if(faceImage) {
#ifdef USE_ROUNDED_CORNERS
    _profileImageView.image = [ImageManipulator roundCornerImageWithImage:faceImage withCornerWidth:10 withCornerHeight:10];
#else
    _profileImageView.image = faceImage;
#endif
    _profileImageView.backgroundColor = [UIColor clearColor];
    [_activityIndicator stopAnimating];
  }
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  DLog(@"FaceView picture request finished");
  // {"error":{"type":"OAuthException","message":"Error validating access token."}}
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
    [_networkErrorAlert show];
    [_networkErrorAlert autorelease];
  } else {
    // Success
    [self performSelectorOnMainThread:@selector(loadNewFaceWithData:) withObject:[UIImage imageWithData:[request responseData]] waitUntilDone:YES];
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
        break;
      case 1:
        [self getProfilePicture];
        break;
      default:
        break;
    }
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
  if(_pictureRequest) {
    [_pictureRequest clearDelegatesAndCancel];
    [_pictureRequest release];
  }
  
  if (_cachedImage) [_cachedImage release];  
  if(_facebookId) [_facebookId release];
  if(_profileImageView) [_profileImageView release];
  if(_activityIndicator) [_activityIndicator release];
  [super dealloc];
}

@end
