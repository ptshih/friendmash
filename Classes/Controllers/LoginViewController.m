//
//  LoginViewController.m
//  Facemash
//
//  Created by Peter Shih on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "RemoteRequest.h"
#import "Constants.h"

@interface LoginViewController (Private)
- (void)authorizeDidSucceed:(NSURL*)url;
- (NSURL *)generateFacebookURL:(NSString *)baseURL params:(NSDictionary *)params;
- (NSString *)getStringFromUrl: (NSString*)url needle:(NSString *)needle;
@end

@implementation LoginViewController

@synthesize authorizeURL = _authorizeURL;
@synthesize delegate;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _alertIsVisible = NO;
  }
  return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  if(isDeviceIPad()) {
    // Disable the indicator
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self showLogin];
}

- (void)showLogin {
  if(_alertIsVisible) return;
  _splashLabel.text = NSLocalizedString(@"authenticating with facebook", @"authenticating with facebook");
  UIDevice *device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
    UIAlertView *fbAlertView = [[UIAlertView alloc] initWithTitle:@"Single Sign-On" message:@"Use Facebook Single Sign-On?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
    [fbAlertView show];
    [fbAlertView autorelease];
    _alertIsVisible = YES;
  } else {
    [self authorizeWithFBAppAuth:NO safariAuth:NO];
  }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      [self performSelector:@selector(authWithSingleSignOn:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.1];
//      [self authorizeWithFBAppAuth:YES safariAuth:YES];
      break;
    case 1:
      [self performSelector:@selector(authWithSingleSignOn:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.1];
//      [self authorizeWithFBAppAuth:NO safariAuth:NO];
      break;
    default:
      break;
  }
  _alertIsVisible = NO;
}

- (void)authWithSingleSignOn:(NSNumber *)trySingleSignOn {
  BOOL useSingleSignOn = [trySingleSignOn boolValue];
  [self authorizeWithFBAppAuth:useSingleSignOn safariAuth:useSingleSignOn];
}


#pragma mark OAuth / FBConnect
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth safariAuth:(BOOL)trySafariAuth {  
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 FB_APP_ID, @"client_id",
                                 @"user_agent", @"type",
                                 @"fbconnect://success", @"redirect_uri",
                                 @"touch", @"display",
                                 @"2", @"sdk",
                                 nil];
  
  NSString* scope = [FB_PERMISSIONS componentsJoinedByString:@","];
  [params setValue:scope forKey:@"scope"];
  
  BOOL didOpenOtherApp = NO;
  UIDevice *device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
    if (tryFBAppAuth) {
      NSString *fbAppUrl = [RemoteRequest serializeURL:@"fbauth://authorize" params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    }
    
    if (trySafariAuth && !didOpenOtherApp) {
      NSString *nextUrl = [NSString stringWithFormat:@"fb%@://authorize", FB_APP_ID];
      [params setValue:nextUrl forKey:@"redirect_uri"];
      
      NSString *fbAppUrl = [RemoteRequest serializeURL:FB_AUTHORIZE_URL params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    }
  }
  
  // If single sign-on failed, open an inline login dialog. This will require the user to
  // enter his or her credentials.
  if (!didOpenOtherApp) {
    _splashView.hidden = NO;
    self.authorizeURL = [NSURL URLWithString:[RemoteRequest serializeURL:FB_AUTHORIZE_URL params:params]];
    NSMutableURLRequest *authorizeRequest = [NSMutableURLRequest requestWithURL:self.authorizeURL];
    [_fbWebView loadRequest:authorizeRequest];
  }  
}

- (NSString *)getStringFromUrl:(NSString *)url needle:(NSString *)needle {
  NSString *str = nil;
  NSRange start = [url rangeOfString:needle];
  if (start.location != NSNotFound) {
    NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
    NSUInteger offset = start.location+start.length;
    str = end.location == NSNotFound
    ? [url substringFromIndex:offset]
    : [url substringWithRange:NSMakeRange(offset, end.location)];  
    str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
  }
  
  return str;
}

- (void)authorizeDidSucceed:(NSURL *)url {
  NSString *q = [url absoluteString];
  NSString *token = [self getStringFromUrl:q needle:@"access_token="];
  NSString *expTime = [self getStringFromUrl:q needle:@"expires_in="];
  NSDate *expirationDate =nil;
  
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal == 0) {
      expirationDate = [NSDate distantFuture];
    } else {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    } 
  } 
  
  if ((token == (NSString *) [NSNull null]) || (token.length == 0)) {
    [self.delegate fbDidNotLoginWithError:nil];
  } else {
    [self.delegate fbDidLoginWithToken:token andExpiration:expirationDate];
  }
  _splashLabel.text = nil;
}


#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
  _splashView.hidden = NO;
  NSURL *url = request.URL;
  
  if ([url.scheme isEqualToString:@"fbconnect"]) {
    if ([[url.resourceSpecifier substringToIndex:8] isEqualToString:@"//cancel"]) {
      NSString *errorCode = [self getStringFromUrl:[url absoluteString] needle:@"error_code="];
      NSString *errorStr = [self getStringFromUrl:[url absoluteString] needle:@"error_msg="];
      if (errorCode) {
        NSDictionary *errorData = [NSDictionary dictionaryWithObject:errorStr forKey:@"error_msg"];
        NSError *error = [NSError errorWithDomain:@"facebookErrDomain" code:[errorCode intValue] userInfo:errorData];
        [self.delegate fbDidNotLoginWithError:error];
      } else {
        [self.delegate fbDidNotLoginWithError:nil];
      }
    } else {
      [self authorizeDidSucceed:url];
    }
    return NO;
  } else if ([self.authorizeURL isEqual:url]) {
    return YES;
  } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
  } else {
    return YES;
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.title = [_fbWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
  _splashView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if (!(([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999) ||
        ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [self.delegate fbDidNotLoginWithError:error];
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
  if(_authorizeURL) [_authorizeURL release];
  if(_fbWebView) [_fbWebView release];
  if(_splashView) [_splashView release];
  if(_splashLabel) [_splashLabel release];
  [super dealloc];
}

@end
