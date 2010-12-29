//
//  FaceView.m
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "FaceView.h"
#import "FriendmashViewController.h"
#import "ImageManipulator.h"
#import "Constants.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "RemoteRequest.h"
#import "CJSONDeserializer.h"
#import <QuartzCore/QuartzCore.h>

#define IPAD_FRAME_WIDTH 1024.0
#define IPHONE_FRAME_WIDTH 480.0

@interface FaceView (Private)

- (void)animateExpand;

- (void)animateCollapse; // This is when touch is cancelled

- (void)animateCollapseSelected; // This is for when we actually select

- (void)faceViewSelected;
  
/**
 This fires an OAuth request to the FB graph API to retrieve a profile picture for the given facebookId
 */
- (void)getPicture;

/**
 This calls the delegate (FriendmashViewController) and sets the isLeftLoaded/isRightLoaded BOOL to YES
 */
- (void)faceViewDidFinishLoading;

// 3.2 only
- (void)createGestureRecognizers;

- (void)endTouch;

@end

@implementation FaceView

@synthesize friendmashViewController = _friendmashViewController;
@synthesize faceImageView = _faceImageView;
@synthesize canvas = _canvas;
@synthesize toolbar = _toolbar;
@synthesize isLeft = _isLeft;
@synthesize isAnimating = _isAnimating;
@synthesize facebookId = _facebookId;
@synthesize delegate = _delegate;
@synthesize networkQueue = _networkQueue;
@synthesize pictureRequest = _pictureRequest;

- (void)awakeFromNib {
  _retryCount = 0;
  currentAnimationType = 0;
  _imageLoaded = NO;
  self.isAnimating = NO;
  _isTouchActive = NO;
  _isTouchCancelled = NO;
  _facebookId = [[NSString alloc] init];
  
  _networkQueue = [[ASINetworkQueue queue] retain];
  [[self networkQueue] setDelegate:self];
  [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
  [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
  [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
  [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
  
  [self createGestureRecognizers];
  
  self.userInteractionEnabled = NO;
}

- (void)prepareFaceViewWithFacebookId:(NSString *)facebookId {
  self.facebookId = facebookId;
  [self getPicture];
}

- (void)getPicture {
  DLog(@"getPicture called with facebookId: %@", self.facebookId);
  self.pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.facebookId andType:@"large" withDelegate:nil];
  [self.networkQueue addOperation:self.pictureRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  DLog(@"FaceView picture request finished");
  // {"error":{"type":"OAuthException","message":"Error validating access token."}}
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    DLog(@"FaceView status code not 200 in request finished, response length: %d", [[request responseData] length]);
    if(statusCode == 400) {
      [FlurryAPI logEvent:@"errorFaceView400"];
      DLog(@"FaceView status code is 400 in request finished, response length: %d", [[request responseData] length]);
      NSDictionary *errorDict = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil] objectForKey:@"error"];
      [self.delegate faceViewDidFailWithError:errorDict];
    } else {
      [FlurryAPI logEvent:@"errorFaceViewFailedPicture"];
      DLog(@"FaceView status code not 200 or 400 in request finished, response length: %d", [[request responseData] length]);
      // There is apparently a change where FB will return null response because their CDN is down
      // For now we're just gonna throw an error and pop out to Launcher
      if([[request responseData] length] == 0) {
        [self.delegate faceViewDidFailPictureDoesNotExist];
      } else {
        _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
        [_networkErrorAlert show];
        [_networkErrorAlert autorelease];
      }
    }
  } else {
    [self performSelectorOnMainThread:@selector(loadNewFaceWithData:) withObject:[UIImage imageWithData:[request responseData]] waitUntilDone:YES];
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  [FlurryAPI logEvent:@"errorFaceViewRequestFailed"];
  DLog(@"Request Failed with Error: %@", [request error]);
  _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
  [_networkErrorAlert show];
  [_networkErrorAlert autorelease];
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
      case 1: {
        [self getPicture];
        break;
      }
      default:
        break;
    }
  }
}

- (void)loadNewFaceWithData:(UIImage *)faceImage {
  if(faceImage) {
#ifdef USE_ROUNDED_CORNERS
    self.faceImageView.image = [ImageManipulator roundCornerImageWithImage:faceImage withCornerWidth:10 withCornerHeight:10];
#else
    self.faceImageView.image = faceImage;
#endif    
    
    self.backgroundColor = [UIColor clearColor];
    _imageLoaded = YES;
  }
  [self faceViewDidFinishLoading];
  self.userInteractionEnabled = YES;
  APP_DELEGATE.touchActive = NO;
}

- (void)faceViewDidFinishLoading {
  if(self.delegate) {
    [self.delegate retain];
    if([self.delegate respondsToSelector:@selector(faceViewDidFinishLoading:)]) {
      [self.delegate faceViewDidFinishLoading:self.isLeft];
    }
    [self.delegate release];
  } 
}

#pragma mark Touches
- (void)createGestureRecognizers {  
  UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  doubleTap.numberOfTapsRequired = 2;
  doubleTap.delegate = self;
  [self addGestureRecognizer:doubleTap];
  
  UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
  longPress.delegate = self;
  [self addGestureRecognizer:longPress];
  
  UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  singleFingerTap.numberOfTapsRequired = 1;
  singleFingerTap.delegate = self;
  [singleFingerTap requireGestureRecognizerToFail:doubleTap];
  [singleFingerTap requireGestureRecognizerToFail:longPress];
  [self addGestureRecognizer:singleFingerTap];
  
  UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
  pinchGesture.delegate = self;
  [self addGestureRecognizer:pinchGesture];
  
  [singleFingerTap release];
  [longPress release];
  [pinchGesture release];
  [doubleTap release];
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
  DLog(@"detected tap gesture with state: %d", [gestureRecognizer state]);
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [self endTouch];
    [self faceViewSelected];
  }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
  DLog(@"detected double tap gesture with state: %d", [gestureRecognizer state]);
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    if(self.delegate) {
      [self.delegate retain];
      if([self.delegate respondsToSelector:@selector(faceViewDidZoom: withImage:)]) {
        [self.delegate faceViewDidZoom:self.isLeft withImage:self.faceImageView.image];
      }
      [self.delegate release];
    }
    [self endTouch];
  }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
  DLog(@"detected long press gesture with state: %d", [gestureRecognizer state]);
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    if(self.delegate) {
      [self.delegate retain];
      if([self.delegate respondsToSelector:@selector(faceViewDidZoom: withImage:)]) {
        [self.delegate faceViewDidZoom:self.isLeft withImage:self.faceImageView.image];
      }
      [self.delegate release];
    }
    [self endTouch];
  }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
  DLog(@"detected pinch gesture with state: %d", [sender state]);
  if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
    CGFloat factor = [sender scale];
    DLog(@"scale: %f", [sender scale]);
    if (factor > 1.25) {
      if(self.delegate) {
        [self.delegate retain];
        if (![self.delegate faceViewIsZoomed]) {
          if([self.delegate respondsToSelector:@selector(faceViewDidZoom:withImage:)]) {
            [self.delegate faceViewDidZoom:self.isLeft withImage:self.faceImageView.image];
          }
        }
        [self.delegate release];
      }
      [self endTouch];
    }
  } else if (sender.state == UIGestureRecognizerStateEnded) {
    // Do nothing
  }
}

- (void)endTouch {
  if (_isTouchActive) {
    _isTouchActive = NO;
    self.friendmashViewController.isTouchActive = NO;
    [self animateCollapse];
  }
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  DLog(@"detected gesture should begin with state: %d", [gestureRecognizer state]);
  if(!self.friendmashViewController.isLeftLoaded || !self.friendmashViewController.isRightLoaded || self.friendmashViewController.isTouchActive) {
    if (_isTouchActive) {
      return YES;
    } else {
      return NO;
    }
  } else {
    return YES;
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if(!self.friendmashViewController.isLeftLoaded || !self.friendmashViewController.isRightLoaded || self.friendmashViewController.isTouchActive) {
    // Either left/right is not done loading or one faceview is actively being touched
    return;
  } else {
    _isTouchActive = YES;
    self.friendmashViewController.isTouchActive = YES;
    [self animateExpand];
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  // Only execute codepath if this faceView is currently active
  DLog(@"touch was ended");
  [self endTouch];
}

- (void)faceViewSelected {
  // Tell the delegate this faceview was selected
  if(self.delegate) {
    [self.delegate retain];
    if([self.delegate respondsToSelector:@selector(faceViewDidSelect:)]) {
      [self.delegate faceViewDidSelect:self.isLeft];
    }
    [self.delegate release];
  } 
}

- (void)animateExpand {
  [UIView beginAnimations:@"FaceViewExpand" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.frame = CGRectMake(self.frame.origin.x - 15, self.frame.origin.y - 15, self.frame.size.width + 30, self.frame.size.height + 30);
	[UIView commitAnimations];
}

- (void)animateCollapse {
  [UIView beginAnimations:@"FaceViewCollapse" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.frame = CGRectMake(self.frame.origin.x + 15, self.frame.origin.y + 15, self.frame.size.width - 30, self.frame.size.height - 30);
	[UIView commitAnimations];
}

- (void)animateCollapseSelected {
  [UIView beginAnimations:@"FaceViewCollapseSelected" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];  
	[UIView setAnimationDuration:0.3]; // Fade out is configurable in seconds (FLOAT)
  self.frame = CGRectMake(self.frame.origin.x + 15, self.frame.origin.y + 15, self.frame.size.width - 30, self.frame.size.height - 30);
	[UIView commitAnimations];
}

- (void)dealloc {
  if(_pictureRequest) {
    [_pictureRequest clearDelegatesAndCancel];
    [_pictureRequest release];
  }
  
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  
  if(_facebookId) [_facebookId release];
  if(_faceImageView) [_faceImageView release];
  [super dealloc];
}

@end
