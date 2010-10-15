//
//  LauncherViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "OBOAuthService.h"
#import "OBFacebookOAuthService.h"

@interface LauncherViewController : UIViewController <OBOAuthServiceDelegate, OBClientOperationDelegate> {
  IBOutlet UIView *_launcherView;
  IBOutlet UIActivityIndicatorView *_activityIndicator;
  IBOutlet UISwitch *_gameModeSwitch;
  OBOAuth2Request *_currentUserRequest;
  OBOAuth2Request *_friendsRequest;
  NSMutableURLRequest *_postUserRequest;
  NSMutableURLRequest *_postFriendsRequest;
  
  UIButton *_logoutButton;
}

@property (nonatomic,retain) OBOAuth2Request *currentUserRequest;
@property (nonatomic,retain) OBOAuth2Request *friendsRequest;
@property (nonatomic,retain) NSMutableURLRequest *postUserRequest;
@property (nonatomic,retain) NSMutableURLRequest *postFriendsRequest;

/**
 Start mashing with gender = male
 This will launch FacemashViewController and set the gender iVar to male for retrieving the first set
 */
- (IBAction)male;

/**
 Start mashing with gender = female
 This will launch FacemashViewController and set the gender iVar to female for retrieving the first set
 */
- (IBAction)female;

- (IBAction)settings;

- (IBAction)rankings;

@end
