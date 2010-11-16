//
//  LightboxViewController.h
//  Facemash
//
//  Created by Peter Shih on 11/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface LightboxViewController : UIViewController {
  IBOutlet UIImageView *_profileImageView;
  IBOutlet UIActivityIndicatorView *_activityIndicator;
  NSString *_facebookId;
  ASINetworkQueue *_networkQueue;
  
  UIAlertView *_networkErrorAlert;
}

@property (nonatomic, retain) NSString *facebookId;
@property (retain) ASINetworkQueue *networkQueue;

- (IBAction)dismiss;

@end
