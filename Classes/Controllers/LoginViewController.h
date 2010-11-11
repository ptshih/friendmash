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
- (void)fbDidLoginWithToken:(NSString *)token;
- (void)fbDidNotLoginWithError:(NSError *)error;
@end

@interface LoginViewController : UIViewController {
  IBOutlet UIWebView *_fbWebView;
  NSURL *_authorizeURL;
  id <FacebookLoginDelegate> delegate;
}

@property (nonatomic, retain) NSURL *authorizeURL;
@property (nonatomic, assign) id <FacebookLoginDelegate> delegate;

@end
