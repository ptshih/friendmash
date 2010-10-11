//
//  FaceView.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FaceView.h"
#import "UIImage+RoundedCorner.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"

#define IPAD_FRAME_WIDTH 1024.0
#define IPHONE_FRAME_WIDTH 480.0

@interface FaceView (Private)

- (void)animateToCenter;
- (void)animateOffScreen;
- (BOOL)wasFlicked:(UITouch *)touch;
- (void)getPictureForFacebookId:(NSUInteger)facebookId;

/**
 Resize the FaceView view/borders to fit the dimensions of the returned image
 */
- (void)resizeViewForFaceImage;

/**
 Draw a 1px grey border with a 4px whitespace around the imageview
 */
- (void)drawBorderAroundImage;

@end

@implementation FaceView

@synthesize faceImageView = _faceImageView;
@synthesize canvas = _canvas;
@synthesize isLeft = _isLeft;
@synthesize isAnimating = _isAnimating;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    // Initialization code
    currentAnimationType = 0;
    _imageLoaded = NO;
    self.isAnimating = NO;
  }
  return self;
}

- (void)awakeFromNib {
  _loadingView.layer.cornerRadius = 5.0;
}

/*
- (void)drawRect:(CGRect)rect {
  if(!_imageLoaded) return;
  return;
  // Drawing code
  CGContextRef c = UIGraphicsGetCurrentContext();
  
  CGContextSetRGBStrokeColor(c, 0.6, 0.6, 0.6, 1.0);
  
  CGContextBeginPath(c);
  CGContextMoveToPoint(c, self.faceImageView.frame.origin.x - 5.0, self.faceImageView.frame.origin.y - 5.0);
  CGContextAddLineToPoint(c, self.faceImageView.frame.origin.x + self.faceImageView.frame.size.width + 5.0, self.faceImageView.frame.origin.y - 5.0);
  CGContextAddLineToPoint(c, self.faceImageView.frame.origin.x + self.faceImageView.frame.size.width + 5.0, self.faceImageView.frame.origin.y + self.faceImageView.frame.size.height + 5.0);
  CGContextAddLineToPoint(c, self.faceImageView.frame.origin.x - 5.0, self.faceImageView.frame.origin.y + self.faceImageView.frame.size.height + 5.0);

  CGContextClosePath(c);
  CGContextSetLineWidth(c, 1.0); // this is set from now on until you explicitly change it
  CGContextStrokePath(c);
}
 */

- (void)prepareFaceViewWithFacebookId:(NSUInteger)facebookId {
  myCenter = self.center;
  defaultOrigin = self.center;
  [self getPictureForFacebookId:facebookId];
}

- (void)getPictureForFacebookId:(NSUInteger)facebookId {
  [OBFacebookOAuthService getPictureForUserWithID:[NSNumber numberWithInt:facebookId] withLargeSize:YES withDelegate:self];
}

#pragma mark OBClientOperationDelegate
- (void)obClientOperation:(OBClientOperation *)operation willSendRequest:(NSURLRequest *)request {
  self.isAnimating = YES;
}
- (void)obClientOperation:(OBClientOperation *)operation failedToSendRequest:(NSURLRequest *)request withError:(NSError *)error {
}
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request {
  NSLog(@"response: %@",[[NSString alloc] initWithData:[operation responseData] encoding:4]);
  [self performSelectorOnMainThread:@selector(loadNewFaceWithData:) withObject:[operation responseData] waitUntilDone:YES];

}
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request whichFailedWithError:(NSError *)error {
  
}

- (void)loadNewFaceWithData:(NSData *)faceData {
//  self.faceImageView.image = [UIImage imageWithData:faceData];
  UIImage *faceImage = [UIImage imageWithData:faceData];
  if(!faceImage) {
    NSLog(@"wtf");
    [_spinner stopAnimating];
    [_loadingView removeFromSuperview];
     _imageLoaded = YES;
    self.isAnimating = NO;
    return;
  }
  self.faceImageView.image = [faceImage roundedCornerImage:5.0 borderSize:0.0];
  self.backgroundColor = [UIColor clearColor];
  [self resizeViewForFaceImage];
   _imageLoaded = YES;
  [_spinner stopAnimating];
  [_loadingView removeFromSuperview];
  self.isAnimating = NO;
}

- (void)resizeViewForFaceImage {
//  CGFloat imageWidth = self.faceImageView.image.size.width;
//  CGFloat imageHeight = self.faceImageView.image.size.height;
//  CGFloat aspectX = self.faceImageView.image.size.width / self.faceImageView.image.size.height;
//  CGFloat aspectY = self.faceImageView.image.size.height / self.faceImageView.image.size.width;
  
//  [self setNeedsDisplay];
  
  

//  if(imageWidth > imageHeight) {
//    CGFloat newHeight = floor(452 / aspectX) + 2;
//    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y + ((452 - newHeight) / 4) , 452, newHeight);
//    self.faceImageView.frame = CGRectMake(self.faceImageView.frame.origin.x, self.faceImageView.frame.origin.y, 440, floor(440 / aspectX));
//    _borderView.frame = CGRectMake(_borderView.frame.origin.x, _borderView.frame.origin.y, 450, floor(450 / aspectX) + 1);
//    
//  } else if(imageWidth < imageHeight) {
//    CGFloat newWidth = floor(452 / aspectY) + 2;
//    self.frame = CGRectMake(self.frame.origin.x + ((452 - newWidth) / 4), self.frame.origin.y, newWidth, 452);
//    self.faceImageView.frame = CGRectMake(self.faceImageView.frame.origin.x, self.faceImageView.frame.origin.y, floor(440 / aspectY), 440);
//    _borderView.frame = CGRectMake(_borderView.frame.origin.x, _borderView.frame.origin.y, floor(450 / aspectY) + 1, 450);
//  }

  
  NSLog(@"imageview width: %g, height: %g",self.faceImageView.frame.size.width, self.faceImageView.frame.size.height);
  NSLog(@"image width: %g, height: %g",self.faceImageView.image.size.width, self.faceImageView.image.size.height);
  NSLog(@"frame width: %g, height: %g", self.frame.size.width, self.frame.size.height);

  // need to resize relative to aspect ratio
  
}

- (void)drawBorderAroundImage {
  
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if(self.isAnimating) return;
  [self.canvas bringSubviewToFront:self];
  touchOrigin = [[touches anyObject] locationInView:self.canvas];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if(self.isAnimating) return;
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvas];
  CGFloat diffX = touchOrigin.x - location.x;
  CGFloat diffY = touchOrigin.y - location.y;
  NSLog(@"diffX: %f, diffY: %f",diffX, diffY);
  self.center = CGPointMake(self.center.x - diffX, self.center.y - diffY);

  NSLog(@"touches moved to loc: %@, new center: %@",[NSValue valueWithCGPoint:location], [NSValue valueWithCGPoint:self.center]);
  touchOrigin = [touch locationInView:self.canvas];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if(self.isAnimating) return;
  UITouch *touch = [touches anyObject];
  BOOL flicked = [self wasFlicked:touch];
  NSLog(@"was flicked: %d",flicked);
//  self.center = defaultOrigin;
  
  CGFloat frameWidth;
  if(isDeviceIPad()) {
    frameWidth = IPAD_FRAME_WIDTH;
  } else {
    frameWidth = IPHONE_FRAME_WIDTH;
  }

  if(flicked) {
    [self animateOffScreen];
  } else if((self.center.x - DRAG_THRESHOLD) <= 0.0 && self.isLeft) {
    [self animateOffScreen];
  } else if((self.center.x + DRAG_THRESHOLD) >= frameWidth && !self.isLeft) {  
    [self animateOffScreen];
  } else {
    [self animateToCenter];
  }
}

- (BOOL)wasFlicked:(UITouch *)touch {
  CGPoint endPoint = [touch locationInView:self];
  CGPoint startPoint = [touch previousLocationInView:self];
  double diffX = endPoint.x - startPoint.x;
  double diffY = endPoint.y - startPoint.y;
  double dist = sqrt(diffX * diffX + diffY * diffY);
  
  if(diffX > 0 && self.isLeft) return NO;
  if(diffX < 0 && !self.isLeft) return NO;
  
  NSLog(@"Last dist = %f", dist);
  
  return dist > FLICK_THRESHOLD; // experiment with best value
}

- (void)animateOffScreen {
  self.isAnimating = YES;
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
  self.isAnimating = YES;
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
	self.userInteractionEnabled = YES;
  if(currentAnimationType == FaceViewAnimationOffScreen) {
    if(self.delegate) {
      [self.delegate retain];
      if([self.delegate respondsToSelector:@selector(faceViewDidAnimateOffScreen:)]) {
        [self.delegate faceViewDidAnimateOffScreen:self];
      }
      [self.delegate release];
    }
  }
  self.isAnimating = NO;
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  
}

- (void)dealloc {
  [_faceImageView release];
  [super dealloc];
}


@end
