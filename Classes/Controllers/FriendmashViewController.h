//
//  FriendmashViewController.h
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FaceView.h"
#import "MashCacheDelegate.h"

/**
 Need to make sure that we don't allow both left and right views to be dismissed at the same time
 */

typedef enum {
  FriendmashGameModeNormal = 0,
  FriendmashGameModeFriends = 1,
  FriendmashGameModeNetwork = 2,
  FriendmashGameModeSchool = 3
} FriendmashGameMode;

@class OverlayView;
@class ThumbsView;
@class ASIHTTPRequest;

@class MashCache;

@interface FriendmashViewController : UIViewController <FaceViewDelegate, MashCacheDelegate> {
  IBOutlet UIToolbar *_toolbar;
  IBOutlet UIButton *_remashButton;
  ASIHTTPRequest *_resultsRequest;
  NSString *_gender;
  NSString *_leftUserId;
  NSString *_rightUserId;
  NSUInteger _gameMode;
  
  FaceView *_leftView;
  FaceView *_rightView;
  FaceView *_tmpLeftView;
  FaceView *_tmpRightView;
  BOOL _isLeftLoaded;
  BOOL _isRightLoaded;
  BOOL _isTouchActive;
  
  
  UIAlertView *_noContentAlert;
  UIAlertView *_networkErrorAlert;
  UIAlertView *_oauthErrorAlert;
  UIAlertView *_fbPictureErrorAlert;
  
  BOOL _faceViewDidError;
  
  OverlayView *_helpView;
  
  UIView *_leftContainerView;
  UIView *_rightContainerView;
  
  UIView *_leftLoadingView;
  UIView *_rightLoadingView;
  
  ThumbsView *_leftThumbsView;
  ThumbsView *_rightThumbsView;

  UIImageView *_refreshSpinner;
  UIImageView *_refreshFrame;
  
  MashCache *_mashCache;
  BOOL _isMashLoaded;
}

@property (nonatomic,retain) FaceView *leftView;
@property (nonatomic,retain) FaceView *rightView;
@property (nonatomic,assign) BOOL isLeftLoaded;
@property (nonatomic,assign) BOOL isRightLoaded;
@property (nonatomic,assign) BOOL isTouchActive;
@property (nonatomic,retain) ASIHTTPRequest *resultsRequest;
@property (nonatomic,retain) NSString *gender;
@property (nonatomic,retain) NSString *leftUserId;
@property (nonatomic,retain) NSString *rightUserId;
@property (nonatomic,assign) NSUInteger gameMode;

@property (nonatomic, retain) UIView *leftContainerView;
@property (nonatomic, retain) UIView *rightContainerView;
@property (nonatomic, retain) UIView *leftLoadingView;
@property (nonatomic, retain) UIView *rightLoadingView;
@property (nonatomic, retain) ThumbsView *leftThumbsView;
@property (nonatomic, retain) ThumbsView *rightThumbsView;

@property (nonatomic, retain) MashCache *mashCache;

- (IBAction)showHelp;
- (IBAction)back;
- (IBAction)remash;

@end

