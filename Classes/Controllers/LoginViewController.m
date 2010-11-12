//
//  LoginViewController.m
//  Facemash
//
//  Created by Peter Shih on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "Constants.h"

@interface LoginViewController (Private)
- (void)authorizeFacebook;
- (void)authorizeDidSucceed:(NSURL*)url;
- (NSURL *)generateFacebookURL:(NSString *)baseURL params:(NSDictionary *)params;
- (NSString *)getStringFromUrl: (NSString*)url needle:(NSString *)needle;
@end

@implementation LoginViewController

@synthesize authorizeURL = _authorizeURL;
@synthesize delegate;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self authorizeFacebook];
}

#pragma mark OAuth / FBConnect
- (void)authorizeFacebook {
  _splashLabel.text = NSLocalizedString(@"Authenticating with Facebook...", @"Authenticating with Facebook...");
  
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 FB_APP_ID, @"client_id",
                                 @"user_agent", @"type", 
                                 @"fbconnect://success", @"redirect_uri",
                                 @"touch", @"display", 
                                 @"ios", @"sdk",
                                 nil];
  
  NSString* scope = [FB_PERMISSIONS componentsJoinedByString:@","];
  [params setValue:scope forKey:@"scope"];
  
  self.authorizeURL = [self generateFacebookURL:FB_AUTHORIZE_URL params:params];
  NSMutableURLRequest *authorizeRequest = [NSMutableURLRequest requestWithURL:_authorizeURL];
  [_fbWebView loadRequest:authorizeRequest];
}

- (NSURL *)generateFacebookURL:(NSString *)baseURL params:(NSDictionary *)params {
  if (params) {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in params.keyEnumerator) {
      NSString *value = [params objectForKey:key];
      NSString *escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
      
      [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
      [escaped_value release];
    }
    
    NSString *query = [pairs componentsJoinedByString:@"&"];
    NSString *url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
    return [NSURL URLWithString:url];
  } else {
    return [NSURL URLWithString:baseURL];
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
  _splashLabel.text = NSLocalizedString(@"Authenticated with Facebook...", @"Authenticated with Facebook...");
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
  _splashLabel.text = @"";
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
  } else if ([_authorizeURL isEqual:url]) {
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
  _titleLabel.text = [_fbWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
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
  if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) return YES;
  else return NO;
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
  [super dealloc];
}

@end
