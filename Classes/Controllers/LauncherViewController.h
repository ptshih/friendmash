//
//  LauncherViewController.h
//  Friendmash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface LauncherViewController : UIViewController <ProfileDelegate, UIActionSheetDelegate> {
  IBOutlet UIView *_launcherView;
  IBOutlet UIButton *_modeButton;
  IBOutlet UIScrollView *_statsView;
  ASINetworkQueue *_networkQueue;
  ASIHTTPRequest *_statsRequest;
  UILabel *_statsLabel;
  UILabel *_statsNextLabel;
  BOOL _isVisible;
  BOOL _isResume;
  NSInteger _gameMode;
  NSArray *_statsArray;
  NSInteger _statsCounter;
}

@property (nonatomic, assign) UIView *launcherView;
@property (nonatomic, retain) UILabel *statsLabel;
@property (nonatomic, retain) UILabel *statsNextLabel;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic,retain) ASIHTTPRequest *statsRequest;
@property (nonatomic, retain) NSArray *statsArray;


/**
 Start mashing with gender = male
 This will launch FriendmashViewController and set the gender iVar to male for retrieving the first set
 */
- (IBAction)male;

/**
 Start mashing with gender = female
 This will launch FriendmashViewController and set the gender iVar to female for retrieving the first set
 */
- (IBAction)female;

- (IBAction)profile;

- (IBAction)rankings;

- (IBAction)about;

- (IBAction)modeSelect:(UIButton *)modeButton;

@end
