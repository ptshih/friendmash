//
//  LightboxViewController.h
//  Friendmash
//
//  Created by Peter Shih on 11/16/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class ASIHTTPRequest;

@interface LightboxViewController : UIViewController <UIGestureRecognizerDelegate> {
  IBOutlet UIImageView *_profileImageView;
  IBOutlet UIActivityIndicatorView *_activityIndicator;
  UIImage *_cachedImage;
  NSString *_facebookId;
  ASIHTTPRequest *_pictureRequest;
  
  UIAlertView *_networkErrorAlert;
}

@property (nonatomic, retain) UIImage *cachedImage;
@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, retain) ASIHTTPRequest *pictureRequest;

- (IBAction)dismiss;

@end
