//
//  WebViewController.m
//  Friendmash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "WebViewController.h"
#import "Constants.h"

@interface WebViewController (Private)

- (void)setupToolbar;

@end

@implementation WebViewController

@synthesize myWebView = _myWebView;
@synthesize myToolbar = _myToolbar;
@synthesize navBarItem = _navBarItem;

@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize stopButton = _stopButton;
@synthesize refreshButton = _refreshButton;
@synthesize activityView = _activityView;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Custom initialization
		_isRefreshState = NO;
	}
	return self;
}

- (void)setWebViewTitle:(NSString *)webViewTitle {
	[self.navBarItem setTitle:webViewTitle];
}

- (void)loadURL:(NSString *)urlString {
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[self.myWebView loadRequest:req];
}

- (void)loadURLRequest:(NSURLRequest *)urlRequest {
	[self.myWebView loadRequest:urlRequest];
}

- (IBAction)dismissView {
	if(self.myWebView.loading) {
		[self.myWebView stopLoading];
	}
	[self dismissModalViewControllerAnimated:YES];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
  [self setupToolbar];
}

- (void)setupToolbar {
  self.activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	UIBarButtonItem *actButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
	self.navBarItem.rightBarButtonItem = actButton;
	[actButton release];
	
	self.backButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tb_icon_prev.png"] style:UIBarButtonItemStylePlain target:self.myWebView action:@selector(goBack)] autorelease];
	UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.forwardButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tb_icon_next.png"] style:UIBarButtonItemStylePlain target:self.myWebView action:@selector(goForward)] autorelease];
	UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.stopButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self.myWebView action:@selector(stopLoading)] autorelease];
	UIBarButtonItem *flexibleItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];	
	UIBarButtonItem *actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(moreActions)] autorelease];
  
	self.refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.myWebView action:@selector(reload)] autorelease];
	
	NSArray *bararray = [[NSArray alloc] initWithObjects:self.backButton, flexibleItem1, self.forwardButton, flexibleItem2, self.stopButton, flexibleItem3, actionButton, nil];
	self.myToolbar.items = bararray;
	
	[bararray release];
	[flexibleItem1 release];
	[flexibleItem2 release];
	[flexibleItem3 release];
}


#pragma mark -
#pragma mark UIWebViewDelegate Functions

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self.activityView startAnimating];
	self.backButton.enabled = [self.myWebView canGoBack];
	self.forwardButton.enabled = [self.myWebView canGoForward];
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.myToolbar.items];
	[array replaceObjectAtIndex:4 withObject:self.stopButton];
	self.myToolbar.items = array;
	[array release];
	//stopButton.enabled = YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.activityView stopAnimating];
	self.backButton.enabled = [self.myWebView canGoBack];
	self.forwardButton.enabled = [self.myWebView canGoForward];
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.myToolbar.items];
	[array replaceObjectAtIndex:4 withObject:self.refreshButton];
	self.myToolbar.items = array;
	[array release];
	//stopButton.enabled = NO;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self.activityView stopAnimating];
	self.backButton.enabled = [self.myWebView canGoBack];
	self.forwardButton.enabled = [self.myWebView canGoForward];

	NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.myToolbar.items];
	[array replaceObjectAtIndex:4 withObject:self.refreshButton];
	self.myToolbar.items = array;
	[array release];
	//stopButton.enabled = NO;	
}

#pragma mark -
#pragma mark Action Button Functions

- (void)moreActions {
	UIActionSheet *styleAlert =[[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
																							otherButtonTitles:@"Open in Safari", @"Copy link", nil] autorelease];
	styleAlert.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	styleAlert.destructiveButtonIndex = 4;
	[styleAlert showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex {	
  switch (buttonIndex) {
		// opening URL in Safari
    case 0: [[UIApplication sharedApplication] openURL:[[self.myWebView request] URL]]; break;
		// copy URL to clipboard
    case 1: {
			NSString *urlString = [[self.myWebView.request URL] absoluteString];
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			[pasteboard setString:urlString];
			break;
		}
    default: break;	// case 2 is cancel anyway
  }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if(isDeviceIPad()) {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
  } else {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
  }
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
  // IBOutlets
  RELEASE_SAFELY(_myWebView);
  RELEASE_SAFELY(_myToolbar);
  RELEASE_SAFELY(_navBarItem);
  
  // IVARS
  RELEASE_SAFELY(_backButton);
  RELEASE_SAFELY(_forwardButton);
  RELEASE_SAFELY(_stopButton);
  RELEASE_SAFELY(_refreshButton);
  RELEASE_SAFELY(_activityView);
  
	[super dealloc];
}

@end
