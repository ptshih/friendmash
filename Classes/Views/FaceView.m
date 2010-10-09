//
//  FaceView.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FaceView.h"
#import <QuartzCore/QuartzCore.h>

@interface FaceView (Private)

- (void)animateToCenter;
- (void)animateOffScreen;
- (BOOL)wasFlicked:(UITouch *)touch;

@end

@implementation FaceView

@synthesize canvas = _canvas;
@synthesize isLeft = _isLeft;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (void)setDefaultPosition {
  myCenter = self.center;
  defaultOrigin = self.center; 
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.canvas bringSubviewToFront:self];
  touchOrigin = [[touches anyObject] locationInView:self.canvas];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self.canvas];
  CGFloat diffX = touchOrigin.x - location.x;
  CGFloat diffY = touchOrigin.y - location.y;
  NSLog(@"diffX: %f, diffY: %f",diffX, diffY);
  self.center = CGPointMake(self.center.x - diffX, self.center.y - diffY);

  NSLog(@"touches moved to loc: %@, new center: %@",[NSValue valueWithCGPoint:location], [NSValue valueWithCGPoint:self.center]);
  touchOrigin = [touch locationInView:self.canvas];
  return;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  BOOL flicked = [self wasFlicked:touch];
  NSLog(@"was flicked: %d",flicked);
//  self.center = defaultOrigin;
  if(flicked) {
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
  
  return dist > 20.0; // experiment with best value
}

- (void)animateOffScreen {
  CALayer *faceLayer = self.layer;
  
  // Create a keyframe animation to follow a path back to the center
	CAKeyframeAnimation *moveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  moveAnimation.removedOnCompletion = NO;
  CGFloat animationDuration = 0.2;
  
  // Create the path
  CGMutablePathRef thePath = CGPathCreateMutable();
  
  CGFloat midX = self.isLeft ? -ceil(self.frame.size.width/2) : self.canvas.frame.size.width + ceil(self.frame.size.width/2);
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
  
}

- (void)animateToCenter {
  CALayer *faceLayer = self.layer;
  
  // Create a keyframe animation to follow a path back to the center
	CAKeyframeAnimation *moveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  moveAnimation.removedOnCompletion = NO;
  CGFloat animationDuration = 1.0;
  
  // Create the path
  CGMutablePathRef thePath = CGPathCreateMutable();
  
  CGFloat midX = defaultOrigin.x;
	CGFloat midY = defaultOrigin.y;
	CGFloat originalOffsetX = self.center.x - midX;
	CGFloat originalOffsetY = self.center.y - midY;
	CGFloat offsetDivider = 4.0;
  
  BOOL stopBouncing = NO;
	
	// Start the path at the placard's current location
	CGPathMoveToPoint(thePath, NULL, self.center.x, self.center.y);
	CGPathAddLineToPoint(thePath, NULL, midX, midY);
	
	// Add to the bounce path in decreasing excursions from the center
	while (stopBouncing != YES) {
		CGPathAddLineToPoint(thePath, NULL, midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider);
		CGPathAddLineToPoint(thePath, NULL, midX, midY);
    
		offsetDivider += 4;
		animationDuration += 1/offsetDivider;
		if ((abs(originalOffsetX/offsetDivider) < 12) && (abs(originalOffsetY/offsetDivider) < 12)) {
			stopBouncing = YES;
		}
	}
  
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
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	//Animation delegate method called when the animation's finished:
	// restore the transform and reenable user interaction
	self.transform = CGAffineTransformIdentity;
	self.userInteractionEnabled = YES;
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  
}

- (void)dealloc {
  [_canvas release];
  [super dealloc];
}


@end
