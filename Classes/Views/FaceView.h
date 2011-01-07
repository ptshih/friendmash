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
  UIToolbar *_toolbar;
  CGPoint _touchOrigin;
  BOOL _isLeft;
  BOOL _isAnimating;
  BOOL _imageLoaded;
  id <FaceViewDelegate> _delegate;
  NSUInteger currentAnimationType;
  NSString *_facebookId;
  BOOL _isTouchActive;
  BOOL _isTouchCancelled;
  
  ASIHTTPRequest *_pictureRequest;
  NSUInteger _retryCount;
  
  UIAlertView *_networkErrorAlert;
}

@property (nonatomic, assign) FriendmashViewController *friendmashViewController;
@property (nonatomic, retain) UIImageView *faceImageView;
@property (nonatomic, assign) UIView *canvas;
@property (nonatomic, assign) UIToolbar *toolbar;
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, assign) id <FaceViewDelegate> delegate;
@property (nonatomic, retain) ASIHTTPRequest *pictureRequest;

/**
 This method prepares the FaceView by setting the local iVar for _facebookId and the default origin for the FaceView
 It then calls getPictureForFacebookId which fires off the request to FB to get the profile picture
 */
- (void)prepareFaceViewWithFacebookId:(NSString *)facebookId;

- (void)loadNewFaceWithImage:(UIImage *)faceImage;

@end
