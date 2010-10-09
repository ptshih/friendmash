//
//  FacemashViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceView.h"

#import "OBOAuthService.h"
#import "OBFacebookOAuthService.h"

@interface FacemashViewController : UIViewController <OBOAuthServiceDelegate> {
  FaceView *_leftView;
  FaceView *_rightView;
}

@property (nonatomic, retain) FaceView *leftView;
@property (nonatomic, retain) FaceView *rightView;

- (void)fbLogin;
- (void)fbLogout;

@end

