//
//  WebViewController.h
//  Friendmash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

//#define kFixedItemWidthPortrait 60
//#define kFixedItemWidthLandscape 140

@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
	IBOutlet UIWebView *_myWebView;
	IBOutlet UIToolbar *_myToolbar;
	IBOutlet UINavigationItem *_navBarItem;
	UIBarButtonItem *_backButton;
	UIBarButtonItem *_forwardButton;
	UIBarButtonItem *_stopButton;
	UIBarButtonItem *_refreshButton;
	UIActivityIndicatorView *_activityView;
	BOOL _isRefreshState;
}

@property (nonatomic, retain) UIWebView *myWebView;
@property (nonatomic, retain) UIToolbar *myToolbar;
@property (nonatomic, retain) UINavigationItem *navBarItem;

@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) UIBarButtonItem *forwardButton;
@property (nonatomic, retain) UIBarButtonItem *stopButton;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;

- (void)loadURL:(NSString *)urlString;
- (void)loadURLRequest:(NSURLRequest *)urlRequest;
- (void)moreActions;
- (void)setWebViewTitle:(NSString *)webViewTitle;

- (IBAction)dismissView;

@end
