//
//  FaceView.h
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FLICK_THRESHOLD 20.0
#define IPAD_DRAG_THRESHOLD 120.0
#define IPHONE_DRAG_THRESHOLD 60.0

/**
 Profile Pictures are 200px wide, variable height up to 602px
 API: graph.facebook.com/{userId}/picture?type=large
 */
@class FaceView;
@class FriendmashViewController;
@class ASIHTTPRequest;

@protocol FaceViewDelegate <NSObject>
@optional
- (BOOL)faceViewIsZoomed;
- (void)faceViewDidFinishLoading:(BOOL)isLeft;
- (void)faceViewDidFailWithError:(NSDictionary *)errorDict;
- (void)faceViewDidFailPictureDoesNotExist;
- (void)faceViewDidSelect:(BOOL)isLeft;
- (void)faceViewDidZoom:(BOOL)isLeft withImage:(UIImage *)image;
@end

@interface FaceView : UIView <UIGestureRecognizerDelegate> {
  IBOutlet UIImageView *_faceImageView;
  FriendmashViewController *_friendmashViewController;
  UIView *_canvas;
  BOOL _isLeft;
  BOOL _isAnimating;
  BOOL _imageLoaded;
  id <FaceViewDelegate> _delegate;
  NSString *_facebookId;
  BOOL _isTouchActive;
}

@property (nonatomic, assign) FriendmashViewController *friendmashViewController;
@property (nonatomic, retain) UIImageView *faceImageView;
@property (nonatomic, assign) UIView *canvas;
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, assign) id <FaceViewDelegate> delegate;

- (void)loadNewFaceWithImage:(UIImage *)faceImage;

@end
