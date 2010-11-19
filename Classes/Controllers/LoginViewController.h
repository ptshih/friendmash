//
//  LoginViewController.h
//  Facemash
//
//  Created by Peter Shih on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FacebookLoginDelegate <NSObject>
@optional
- (void)fbDidLoginWithToken:(NSString *)token andExpiration:(NSDate *)expiration;
- (void)fbDidNotLoginWithError:(NSError *)error userDidCancel:(BOOL)userDidCancel;
@end

@interface LoginViewController : UIViewController {
  IBOutlet UIWebView *_fbWebView;
  IBOutlet UIView *_splashView;
  IBOutlet UILabel *_splashLabel;
  IBOutlet UIButton *_ssoButton;
  IBOutlet UIButton *_normalButton;
  IBOutlet UIActivityIndicatorView *_splashActivity;
  NSURL *_authorizeURL;
  id <FacebookLoginDelegate> delegate;
}

@property (nonatomic, retain) NSURL *authorizeURL;
@property (nonatomic, assign) id <FacebookLoginDelegate> delegate;

- (void)resetLoginState;
- (IBAction)ssoLogin;
- (IBAction)normalLogin;
- (IBAction)terms;
- (IBAction)privacy;
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth safariAuth:(BOOL)trySafariAuth;;

@end
