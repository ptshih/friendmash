//
//  FacemashAppDelegate.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FacemashViewController;

@interface FacemashAppDelegate : NSObject <UIApplicationDelegate> {
  UIWindow *window;
  UINavigationController *_navigationController;
  FacemashViewController *_facemashViewController;
  NSMutableDictionary *_currentUserDictionary;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet FacemashViewController *facemashViewController;
@property (nonatomic, retain) NSMutableDictionary *currentUserDictionary;

@end

