//
//  FriendmashViewController.h
//  Friendmash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceView.h"

/**
 Need to make sure that we don't allow both left and right views to be dismissed at the same time
 */

typedef enum {
  FriendmashGameModeNormal = 0,
  FriendmashGameModeFriends = 1,
  FriendmashGameModeNetwork = 2
} FriendmashGameMode;

@class OverlayView;
@class ThumbsView;
@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface FriendmashViewController : UIViewController <FaceViewDelegate> {
  IBOutlet UIToolbar *_toolbar;
  IBOutlet UIButton *_remashButton;
  ASINetworkQueue *_networkQueue;
  ASIHTTPRequest *_resultsRequest;
  ASIHTTPRequest *_bothRequest;
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
  
  NSMutableArray *_recentOpponentsArray;
  
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
}

@property (nonatomic,retain) FaceView *leftView;
@property (nonatomic,retain) FaceView *rightView;
@property (nonatomic,assign) BOOL isLeftLoaded;
@property (nonatomic,assign) BOOL isRightLoaded;
@property (nonatomic,assign) BOOL isTouchActive;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic,retain) ASIHTTPRequest *resultsRequest;
@property (nonatomic,retain) ASIHTTPRequest *bothRequest;
@property (nonatomic,retain) NSString *gender;
@property (nonatomic,retain) NSString *leftUserId;
@property (nonatomic,retain) NSString *rightUserId;
@property (nonatomic,assign) NSUInteger gameMode;
@property (nonatomic,retain) NSMutableArray *recentOpponentsArray;

@property (nonatomic, retain) UIView *leftContainerView;
@property (nonatomic, retain) UIView *rightContainerView;
@property (nonatomic, retain) UIView *leftLoadingView;
@property (nonatomic, retain) UIView *rightLoadingView;
@property (nonatomic, retain) ThumbsView *leftThumbsView;
@property (nonatomic, retain) ThumbsView *rightThumbsView;

- (IBAction)showHelp;
- (IBAction)back;
- (IBAction)remash;

@end

