//
//  FaceView.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FLICK_THRESHOLD 20.0

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

@interface FaceView : UIView {
  UIView *_canvas;
  CGPoint defaultOrigin;
  CGPoint myCenter;
  CGPoint touchOrigin;
  BOOL _isLeft;
  id <FaceViewDelegate> _delegate;
  NSUInteger currentAnimationType;
}

@property (nonatomic, assign) UIView *canvas;
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) id <FaceViewDelegate> delegate;

- (void)setDefaultPosition;

@end
