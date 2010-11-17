//
//  FaceView.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FaceView.h"
#import "FacemashViewController.h"
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

/**
 This method performs an animation that bounces the FaceView back to it's original position
 */
- (void)animateToCenter;

/**
 This method performs an animation that slides the FaceView off the screen
 */
- (void)animateOffScreen;

/**
 This method tries to detect based on x,y touch coordinate changes if the user flicked a FaceView
 */
- (BOOL)wasFlicked:(UITouch *)touch;

/**
 This gets an ad from FM servers instead of FB picture
 */
- (void)getAd;

/**
 This fires an OAuth request to the FB graph API to retrieve a profile picture for the given facebookId
 */
- (void)getPicture;

/**
 This calls the delegate (FacemashViewController) and sets the isLeftLoaded/isRightLoaded BOOL to NO
 */
- (void)faceViewDidUnload;

/**
 This calls the delegate (FacemashViewController) and sets the isLeftLoaded/isRightLoaded BOOL to YES
 */
- (void)faceViewDidFinishLoading;

@end

@implementation FaceView

@synthesize facemashViewController = _facemashViewController;
@synthesize faceImageView = _faceImageView;
@synthesize canvas = _canvas;
@synthesize toolbar = _toolbar;
@synthesize isLeft = _isLeft;
@synthesize isAnimating = _isAnimating;
@synthesize facebookId = _facebookId;
@synthesize delegate = _delegate;
@synthesize networkQueue = _networkQueue;

- (void)awakeFromNib {
  _retryCount = 0;
  currentAnimationType = 0;
  _imageLoaded = NO;
  self.isAnimating = NO;
  _touchAllowed = YES;
  _facebookId = [[NSString alloc] init];
  
  _networkQueue = [[ASINetworkQueue queue] retain];
  [[self networkQueue] setDelegate:self];
  [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
  [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
  [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
  [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
  
  _loadingView.layer.cornerRadius = 10.0;
  self.userInteractionEnabled = NO;
}

- (void)prepareFaceViewWithFacebookId:(NSString *)facebookId {
  self.facebookId = facebookId;
  myCenter = self.center;
  defaultOrigin = self.center;
  
  // Check for an ad injection
  NSString *adFlag = [self.facebookId substringToIndex:5];
  if([adFlag isEqualToString:@"fmad_"]) {
    [self getAd];
  } else {
    [self getPicture];
  }
}

- (void)getAd {
  // This fetches an ad from FM servers instead of FB
  ASIHTTPRequest *adRequest = [RemoteRequest getRequestForAdWithAdId:self.facebookId withDelegate:nil];
  [self.networkQueue addOperation:adRequest];
  [self.networkQueue go];
}

- (void)getPicture {
  DLog(@"getPicture called with facebookId: %@", self.facebookId);
  ASIHTTPRequest *pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.facebookId andType:@"large" withDelegate:nil];
  [self.networkQueue addOperation:pictureRequest];
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
      DLog(@"FaceView status code is 400 in request finished, response length: %d", [[request responseData] length]);
      NSDictionary *errorDict = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil] objectForKey:@"error"];
      [self.delegate faceViewDidFailWithError:errorDict];
    } else {
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

- (void)requestFailed:(ASIHTTPRequest *)request
{
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
        // Check for an ad injection
        NSString *adFlag = [self.facebookId substringToIndex:5];
        if([adFlag isEqualToString:@"fmad_"]) {
          [self getAd];
        } else {
          [self getPicture];
        }
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
    [_spinner stopAnimating];
    [_loadingView removeFromSuperview];
  }
  [self faceViewDidFinishLoading];
  self.userInteractionEnabled = YES;
  APP_DELEGATE.touchActive = NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if(!self.facemashViewController.isLeftLoaded || !self.facemashViewController.isRightLoaded) return;
  if(!APP_DELEGATE.touchActive) {
    APP_DELEGATE.touchActive = YES;
    _touchAllowed = YES;
    [self.canvas bringSubviewToFront:self];
    [self.canvas bringSubviewToFront:self.toolbar];
    touchOrigin = [[touches anyObject] locationInView:self.canvas];
  } else {
    _touchAllowed = NO;
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if(!_touchAllowed) return;
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvas];
  CGFloat diffX = touchOrigin.x - location.x;
  CGFloat diffY = touchOrigin.y - location.y;
//  NSLog(@"diffX: %f, diffY: %f",diffX, diffY);
  self.center = CGPointMake(self.center.x - diffX, self.center.y - diffY);

//  NSLog(@"touches moved to loc: %@, new center: %@",[NSValue valueWithCGPoint:location], [NSValue valueWithCGPoint:self.center]);
  touchOrigin = [touch locationInView:self.canvas];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if(!_touchAllowed) return;
  UITouch *touch = [touches anyObject];
  BOOL flicked = [self wasFlicked:touch];
//  NSLog(@"was flicked: %d",flicked);
//  self.center = defaultOrigin;
  
  CGFloat frameWidth;
  CGFloat dragThreshold;
  if(isDeviceIPad()) {
    frameWidth = IPAD_FRAME_WIDTH;
    dragThreshold = IPAD_DRAG_THRESHOLD;
  } else {
    frameWidth = IPHONE_FRAME_WIDTH;
    dragThreshold = IPHONE_DRAG_THRESHOLD;
  }

  if(flicked) {
    [self animateOffScreen];
  } else if((self.center.x - dragThreshold) <= 0.0 && self.isLeft) {
    [self animateOffScreen];
  } else if((self.center.x + dragThreshold) >= frameWidth && !self.isLeft) {  
    [self animateOffScreen];
  } else {
    [self animateToCenter];
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (BOOL)wasFlicked:(UITouch *)touch {
  CGPoint endPoint = [touch locationInView:self];
  CGPoint startPoint = [touch previousLocationInView:self];
  double diffX = endPoint.x - startPoint.x;
  double diffY = endPoint.y - startPoint.y;
  double dist = sqrt(diffX * diffX + diffY * diffY);
  
  if(diffX > 0 && self.isLeft) return NO;
  if(diffX < 0 && !self.isLeft) return NO;
  
//  NSLog(@"Last dist = %f", dist);
  
  return dist > FLICK_THRESHOLD; // experiment with best value
}

- (void)animateOffScreen {
  APP_DELEGATE.touchActive = YES;
  CALayer *faceLayer = self.layer;
  
  // Create a keyframe animation to follow a path back to the center
	CAKeyframeAnimation *moveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  moveAnimation.removedOnCompletion = NO;
  CGFloat animationDuration = 0.25;
  
  // Create the path
  CGMutablePathRef thePath = CGPathCreateMutable();
  
  CGFloat midX = self.isLeft ? -(ceil(self.frame.size.width/2)+20) : self.canvas.frame.size.width + (ceil(self.frame.size.width/2)+20);
	CGFloat midY = self.center.y;
	
	// Start the path at the placard's current location
	CGPathMoveToPoint(thePath, NULL, self.center.x, self.center.y);
	CGPathAddLineToPoint(thePath, NULL, midX, midY);
  
  moveAnimation.path = thePath;
  moveAnimation.duration = animationDuration;
  CGPathRelease(thePath);
  
  // Create an animation group to combine the keyframe and basic animations
	CAAnimationGroup *theGroup = [CAAnimationGroup animation];
  
  theGroup.delegate = self;
	theGroup.duration = animationDuration;
	theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	theGroup.animations = [NSArray arrayWithObjects:moveAnimation, nil];
	
	
	// Add the animation group to the layer
	[faceLayer addAnimation:theGroup forKey:@"animateViewOffScreen"];
	
	// Set the placard view's center and transformation to the original values in preparation for the end of the animation
	self.center = CGPointMake(midX, midY);
	self.transform = CGAffineTransformIdentity;
  currentAnimationType = 2;
}

- (void)animateToCenter {
  CALayer *faceLayer = self.layer;
  
  // Create a keyframe animation to follow a path back to the center
	CAKeyframeAnimation *moveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  moveAnimation.removedOnCompletion = NO;
  CGFloat animationDuration = 0.25;
  
  // Create the path
  CGMutablePathRef thePath = CGPathCreateMutable();
  
  CGFloat midX = defaultOrigin.x;
	CGFloat midY = defaultOrigin.y;
	CGFloat originalOffsetX = self.center.x - midX;
	CGFloat originalOffsetY = self.center.y - midY;
	CGFloat offsetDivider = 10.0;
	
	// Start the path at the placard's current location
	CGPathMoveToPoint(thePath, NULL, self.center.x, self.center.y);
//	CGPathAddLineToPoint(thePath, NULL, midX, midY);
	
	// Add to the bounce path in decreasing excursions from the center
  CGPathAddLineToPoint(thePath, NULL, midX - originalOffsetX/offsetDivider, midY - originalOffsetY/offsetDivider);
  CGPathAddLineToPoint(thePath, NULL, midX, midY);
  
  moveAnimation.path = thePath;
  moveAnimation.duration = animationDuration;
  CGPathRelease(thePath);
  
  // Create an animation group to combine the keyframe and basic animations
	CAAnimationGroup *theGroup = [CAAnimationGroup animation];
  
  theGroup.delegate = self;
	theGroup.duration = animationDuration;
	theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	theGroup.animations = [NSArray arrayWithObjects:moveAnimation, nil];
	
	
	// Add the animation group to the layer
	[faceLayer addAnimation:theGroup forKey:@"animateViewToCenter"];
	
	// Set the placard view's center and transformation to the original values in preparation for the end of the animation
	self.center = defaultOrigin;
	self.transform = CGAffineTransformIdentity;
  currentAnimationType = 1;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	//Animation delegate method called when the animation's finished:
	// restore the transform and reenable user interaction
	self.transform = CGAffineTransformIdentity;
  if(currentAnimationType == FaceViewAnimationOffScreen) {
    [self faceViewDidUnload];
  } else if(currentAnimationType = FaceViewAnimationCenter) {
    APP_DELEGATE.touchActive = NO;
    _touchAllowed = NO;
  }
}

- (void)faceViewDidUnload {
  if(self.delegate) {
    [self.delegate retain];
    if([self.delegate respondsToSelector:@selector(faceViewDidAnimateOffScreen:)]) {
      [self.delegate faceViewDidAnimateOffScreen:self.isLeft];
    }
    [self.delegate release];
  } 
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

- (void)dealloc {
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  if(_facebookId) [_facebookId release];
  if(_faceImageView) [_faceImageView release];
  if(_spinner) [_spinner release];
  if(_loadingView) [_loadingView release];
  [super dealloc];
}

@end
