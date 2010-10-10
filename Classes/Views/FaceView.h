//
//  FaceView.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBFacebookOAuthService.h"
#import "OBFacemashUser.h"

#define FLICK_THRESHOLD 20.0
#define DRAG_THRESHOLD 80.0

/**
 Profile Pictures are 200px wide, variable height up to 602px
 API: graph.facebook.com/{userId}/picture?type=large
 */
@class FaceView;

@protocol FaceViewDelegate <NSObject>
@optional
- (void)faceViewWillAnimateOffScreen:(FaceView *)faceView;
- (void)faceViewDidAnimateOffScreen:(FaceView *)faceView;
@end

typedef enum {
  FaceViewAnimationNone = 0,
  FaceViewAnimationCenter = 1,
  FaceViewAnimationOffScreen = 2
} FaceViewAnimationType;

@interface FaceView : UIView <OBClientOperationDelegate> {
  IBOutlet UIImageView *_faceImageView;
  IBOutlet UIActivityIndicatorView *_spinner;
  UIView *_canvas;
  CGPoint defaultOrigin;
  CGPoint myCenter;
  CGPoint touchOrigin;
  BOOL _isLeft;
  BOOL _isAnimating;
  id <FaceViewDelegate> _delegate;
  NSUInteger currentAnimationType;
}

@property (nonatomic, retain) UIImageView *faceImageView;
@property (nonatomic, assign) UIView *canvas;
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) id <FaceViewDelegate> delegate;

- (void)prepareFaceViewWithFacebookId:(NSUInteger)facebookId;

@end
