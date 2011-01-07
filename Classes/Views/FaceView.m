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
#import "RemoteRequest.h"
#import "CJSONDeserializer.h"
#import <QuartzCore/QuartzCore.h>
#import "RemoteOperation.h"

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

- (void)awakeFromNib {
  currentAnimationType = 0;
  _imageLoaded = NO;
  self.isAnimating = NO;
  _isTouchActive = NO;
  _facebookId = [[NSString alloc] init];
  
  [self createGestureRecognizers];
  
  self.userInteractionEnabled = NO;
}

- (void)loadNewFaceWithImage:(UIImage *)faceImage {
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
  
//  UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//  longPress.delegate = self;
//  [self addGestureRecognizer:longPress];
  
  UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  singleFingerTap.numberOfTapsRequired = 1;
  singleFingerTap.delegate = self;
  [singleFingerTap requireGestureRecognizerToFail:doubleTap];
//  [singleFingerTap requireGestureRecognizerToFail:longPress];
  [self addGestureRecognizer:singleFingerTap];
  
  UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
  pinchGesture.delegate = self;
  [self addGestureRecognizer:pinchGesture];
  
  [singleFingerTap release];
//  [longPress release];
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

//- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
//  DLog(@"detected long press gesture with state: %d", [gestureRecognizer state]);
//  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
//  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
//    if(self.delegate) {
//      [self.delegate retain];
//      if([self.delegate respondsToSelector:@selector(faceViewDidZoom: withImage:)]) {
//        [self.delegate faceViewDidZoom:self.isLeft withImage:self.faceImageView.image];
//      }
//      [self.delegate release];
//    }
//    [self endTouch];
//  }
//}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
  DLog(@"detected pinch gesture with state: %d", [sender state]);
  if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
    CGFloat factor = [sender scale];
    DLog(@"scale: %f", [sender scale]);
    if (factor > 1.5) {
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
    [self endTouch];
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
  if(_facebookId) [_facebookId release];
  if(_faceImageView) [_faceImageView release];
  [super dealloc];
}

@end
