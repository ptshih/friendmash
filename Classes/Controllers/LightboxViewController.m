//
//  LightboxViewController.m
//  Facemash
//
//  Created by Peter Shih on 11/16/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "LightboxViewController.h"
#import "Constants.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"
#import "ImageManipulator.h"

@interface LightboxViewController (Private)
- (void)getProfilePicture;
@end

@implementation LightboxViewController

@synthesize facebookId = _facebookId;
@synthesize networkQueue = _networkQueue;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _facebookId = [[NSString alloc] init];
    
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self getProfilePicture];
}

- (IBAction)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)getProfilePicture {
  ASIHTTPRequest *pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.facebookId andType:@"large" withDelegate:nil];
  [self.networkQueue addOperation:pictureRequest];
  [self.networkQueue go];
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

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"FaceView Queue finished");
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
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  if(_facebookId) [_facebookId release];
  if(_profileImageView) [_profileImageView release];
  if(_activityIndicator) [_activityIndicator release];
  [super dealloc];
}

@end
