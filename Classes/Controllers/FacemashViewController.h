//
//  FacemashViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceView.h"
#import "ASIHTTPRequest.h"

/**
 Need to make sure that we don't allow both left and right views to be dismissed at the same time
 */

typedef enum {
  FacemashGameModeNormal = 0,
  FacemashGameModeRandom = 1
} FacemashGameMode;

@interface FacemashViewController : UIViewController <FaceViewDelegate> {
  IBOutlet UIToolbar *_toolbar;
  ASIHTTPRequest *_resultsRequest;
  ASIHTTPRequest *_leftRequest;
  ASIHTTPRequest *_rightRequest;
  ASIHTTPRequest *_bothRequest;
  NSString *_gender;
  NSString *_leftUserId;
  NSString *_rightUserId;
  NSUInteger _gameMode;
  
  FaceView *_leftView;
  FaceView *_rightView;
  BOOL _isLeftLoaded;
  BOOL _isRightLoaded;
}

@property (nonatomic,assign) FaceView *leftView;
@property (nonatomic,assign) FaceView *rightView;
@property (nonatomic,assign) BOOL isLeftLoaded;
@property (nonatomic,assign) BOOL isRightLoaded;
@property (nonatomic,retain) ASIHTTPRequest *resultsRequest;
@property (nonatomic,retain) ASIHTTPRequest *leftRequest;
@property (nonatomic,retain) ASIHTTPRequest *rightRequest;
@property (nonatomic,retain) ASIHTTPRequest *bothRequest;
@property (nonatomic,retain) NSString *gender;
@property (nonatomic,retain) NSString *leftUserId;
@property (nonatomic,retain) NSString *rightUserId;
@property (nonatomic,assign) NSUInteger gameMode;

- (IBAction)back;

// Debug methods
//- (IBAction)sendMashResults;
//- (IBAction)sendMashRequest;
//- (IBAction)sendFriendsList;

@end

