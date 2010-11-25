//
//  FaceView.h
//  Facemash
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
@class FacemashViewController;
@class ASIHTTPRequest;
@class ASINetworkQueue;

@protocol FaceViewDelegate <NSObject>
@optional
- (void)faceViewDidFinishLoading:(BOOL)isLeft;
- (void)faceViewDidFailWithError:(NSDictionary *)errorDict;
- (void)faceViewDidFailPictureDoesNotExist;
- (void)faceViewWillAnimateOffScreen:(BOOL)isLeft;
- (void)faceViewDidAnimateOffScreen:(BOOL)isLeft;
@end

typedef enum {
  FaceViewAnimationNone = 0,
  FaceViewAnimationCenter = 1,
  FaceViewAnimationOffScreen = 2
} FaceViewAnimationType;

@interface FaceView : UIView {
  IBOutlet UIImageView *_faceImageView;
  IBOutlet UIActivityIndicatorView *_spinner;
  IBOutlet UIView *_loadingView;
  FacemashViewController *_facemashViewController;
  UIView *_canvas;
  UIToolbar *_toolbar;
  CGPoint defaultOrigin;
  CGPoint myCenter;
  CGPoint touchOrigin;
  BOOL _isLeft;
  BOOL _isAnimating;
  BOOL _imageLoaded;
  id <FaceViewDelegate> _delegate;
  NSUInteger currentAnimationType;
  NSString *_facebookId;
  BOOL _touchAllowed;
  
  ASINetworkQueue *_networkQueue;
  NSUInteger _retryCount;
  
  UIAlertView *_networkErrorAlert;
}

@property (nonatomic, assign) FacemashViewController *facemashViewController;
@property (nonatomic, retain) UIImageView *faceImageView;
@property (nonatomic, assign) UIView *canvas;
@property (nonatomic, assign) UIToolbar *toolbar;
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, assign) id <FaceViewDelegate> delegate;
@property (retain) ASINetworkQueue *networkQueue;

/**
 This method prepares the FaceView by setting the local iVar for _facebookId and the default origin for the FaceView
 It then calls getPictureForFacebookId which fires off the request to FB to get the profile picture
 */
- (void)prepareFaceViewWithFacebookId:(NSString *)facebookId;

@end
