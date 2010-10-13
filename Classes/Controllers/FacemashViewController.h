//
//  FacemashViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceView.h"
#import "FBConnect.h"
#import "OBOAuthService.h"
#import "OBFacebookOAuthService.h"

/**
 Need to make sure that we don't allow both left and right views to be dismissed at the same time
 */

typedef enum {
  FacemashGameModeNormal = 0,
  FacemashGameModeRandom = 1
} FacemashGameMode;

@interface FacemashViewController : UIViewController <OBClientOperationDelegate, FaceViewDelegate> {
  IBOutlet UIToolbar *_toolbar;
  NSMutableURLRequest *_resultsRequest;
  NSMutableURLRequest *_leftRequest;
  NSMutableURLRequest *_rightRequest;
  NSMutableURLRequest *_bothRequest;
  NSString *_gender;
  NSUInteger _gameMode;
  NSString *_leftUserId;
  NSString *_rightUserId;

  FaceView *_leftView;
  FaceView *_rightView;
  BOOL _isLeftLoaded;
  BOOL _isRightLoaded;
}

@property (nonatomic,assign) FaceView *leftView;
@property (nonatomic,assign) FaceView *rightView;
@property (nonatomic,assign) BOOL isLeftLoaded;
@property (nonatomic,assign) BOOL isRightLoaded;
@property (nonatomic,retain) NSMutableURLRequest *resultsRequest;
@property (nonatomic,retain) NSMutableURLRequest *leftRequest;
@property (nonatomic,retain) NSMutableURLRequest *rightRequest;
@property (nonatomic,retain) NSMutableURLRequest *bothRequest;
@property (nonatomic,retain) NSString *gender;
@property (nonatomic,assign) NSUInteger gameMode;

// Debug methods
//- (IBAction)sendMashResults;
//- (IBAction)sendMashRequest;
//- (IBAction)sendFriendsList;

@end

