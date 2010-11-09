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

@class ASINetworkQueue;

@interface FacemashViewController : UIViewController <FaceViewDelegate> {
  IBOutlet UIToolbar *_toolbar;
  ASINetworkQueue *_networkQueue;
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
  BOOL _shouldGoBack;
  BOOL _isLeftLoaded;
  BOOL _isRightLoaded;
  
  NSMutableArray *_recentOpponentsArray;
}

@property (nonatomic,assign) FaceView *leftView;
@property (nonatomic,assign) FaceView *rightView;
@property (nonatomic,assign) BOOL isLeftLoaded;
@property (nonatomic,assign) BOOL isRightLoaded;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic,retain) ASIHTTPRequest *resultsRequest;
@property (nonatomic,retain) ASIHTTPRequest *leftRequest;
@property (nonatomic,retain) ASIHTTPRequest *rightRequest;
@property (nonatomic,retain) ASIHTTPRequest *bothRequest;
@property (nonatomic,retain) NSString *gender;
@property (nonatomic,retain) NSString *leftUserId;
@property (nonatomic,retain) NSString *rightUserId;
@property (nonatomic,assign) NSUInteger gameMode;
@property (nonatomic,retain) NSMutableArray *recentOpponentsArray;

- (IBAction)back;

@end

