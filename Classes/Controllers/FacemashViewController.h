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

@interface FacemashViewController : UIViewController <OBClientOperationDelegate, FaceViewDelegate> {
  IBOutlet UIToolbar *_toolbar;
  NSMutableURLRequest *_resultsRequest;
  NSMutableURLRequest *_leftRequest;
  NSMutableURLRequest *_rightRequest;
  NSMutableURLRequest *_bothRequest;
  NSString *_gender;
  NSString *_leftUserId;
  NSString *_rightUserId;

  FaceView *_leftView;
  FaceView *_rightView;
}

@property (nonatomic,assign) FaceView *leftView;
@property (nonatomic,assign) FaceView *rightView;
@property (nonatomic,retain) NSMutableURLRequest *resultsRequest;
@property (nonatomic,retain) NSMutableURLRequest *leftRequest;
@property (nonatomic,retain) NSMutableURLRequest *rightRequest;
@property (nonatomic,retain) NSMutableURLRequest *bothRequest;
@property (nonatomic,retain) NSString *gender;

// Debug methods
//- (IBAction)sendMashResults;
//- (IBAction)sendMashRequest;
//- (IBAction)sendFriendsList;

@end

