//
//  LauncherViewController.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"

@interface LauncherViewController : UIViewController <ProfileDelegate> {
  IBOutlet UIView *_launcherView;
  IBOutlet UISwitch *_gameModeSwitch;
  IBOutlet UIView *_splashView;
  IBOutlet UILabel *_splashLabel;
}

@property (nonatomic, assign) UIView *launcherView;
@property (nonatomic, assign) UIView *splashView;


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

- (IBAction)profile;

- (IBAction)rankings;

@end
