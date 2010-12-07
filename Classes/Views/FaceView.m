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
- (void)startTouchTimer {
  _touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(touchesHeld:) userInfo:nil repeats:NO];
}

- (void)touchesHeld:(NSTimer*)timer {
  if(_isTouchActive) {
    self.friendmashViewController.isTouchActive = NO;
    _isTouchActive = NO;
    [self animateCollapse];
    
    if(self.delegate) {
      [self.delegate retain];
      if([self.delegate respondsToSelector:@selector(faceViewDidZoom:)]) {
        [self.delegate faceViewDidZoom:self.isLeft];
      }
      [self.delegate release];
    } 
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if(!self.friendmashViewController.isLeftLoaded || !self.friendmashViewController.isRightLoaded || self.friendmashViewController.isTouchActive) {
    // Either left/right is not done loading or one faceview is actively being touched
    return;
  } else {
    //    [self.canvas bringSubviewToFront:self];
    //    [self.canvas bringSubviewToFront:self.toolbar];
    
    [self startTouchTimer];
    self.friendmashViewController.isTouchActive = YES;
    _isTouchActive = YES;
    _touchOrigin = [[touches anyObject] locationInView:self];
    [self animateExpand];
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  // Only execute codepath if this faceView is currently active
  if(_isTouchActive) {
    CGPoint location = [[touches anyObject] locationInView:self];
    
    
    CGFloat diffX = fabsf(_touchOrigin.x - (location.x - 15.0));
    CGFloat diffY = fabsf(_touchOrigin.y - (location.y - 15.0));
    DLog(@"originX: %f, originY: %f, locX: %f, locY: %f, diffX: %f, diffY: %f", _touchOrigin.x, _touchOrigin.y, location.x, location.y, diffX, diffY);
    // Frame for iPhone is 200x200, 230x230 (when expanded)
    // This means that from the center of the picture, its +/- 115 in the X and Y direction before the edge
    // So when the abs(diff) > ~115, we should cancel the touch
    
    if (diffX > 25.0 || diffY > 25.0) {
      [self touchesCancelled:touches withEvent:event];
    } else {
      [super touchesMoved:touches withEvent:event];
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  // Only execute codepath if this faceView is currently active
  if(_isTouchActive) {
    DLog(@"touch was ended");
    self.friendmashViewController.isTouchActive = NO;
    _isTouchActive = NO;
    [self faceViewSelected];
    [self animateCollapseSelected];
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  // Only execute codepath if this faceView is currently active
  DLog(@"touch was cancelled");
  if(_isTouchActive) {
    if ([_touchTimer isValid]) [_touchTimer invalidate];
    self.friendmashViewController.isTouchActive = NO;
    _isTouchActive = NO;
    [self animateCollapse];
  }
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
