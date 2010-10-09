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

@interface FacemashViewController : UIViewController <OBClientOperationDelegate, OBOAuthServiceDelegate, FaceViewDelegate> {
  OBOAuth2Request *_currentUserRequest;
  FaceView *_leftView;
  FaceView *_rightView;
}

@property (nonatomic, retain) FaceView *leftView;
@property (nonatomic, retain) FaceView *rightView;

- (void)fbLogin;
- (void)fbLogout;

@end

