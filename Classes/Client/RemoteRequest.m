//
//  RemoteRequest.m
//  Facemash
//
//  Created by Peter Shih on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RemoteRequest.h"
#import "ASIHTTPRequest.h"
#import "Constants.h"

@implementation RemoteRequest

+ (ASIHTTPRequest *)getRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params withDelegate:(id)delegate {
//  [getRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  
  NSString *getURLString = params ? [NSString stringWithFormat:@"%@?%@", baseURLString, params] : baseURLString;
  NSURL *getURL = [NSURL URLWithString:getURLString];
  
  ASIHTTPRequest *getRequest = [ASIHTTPRequest requestWithURL:getURL];
  [getRequest setDelegate:delegate];
  [getRequest setNumberOfTimesToRetryOnTimeout:2];
  [getRequest setAllowCompressedResponse:YES];
  [getRequest setRequestMethod:@"GET"];
  [getRequest addRequestHeader:@"X-User-Id" value:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  [getRequest addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [getRequest addRequestHeader:@"X-Device-Model" value:[[UIDevice currentDevice] model]];
  [getRequest addRequestHeader:@"X-App-Version" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
  [getRequest addRequestHeader:@"X-System-Name" value:[[UIDevice currentDevice] systemName]];
  [getRequest addRequestHeader:@"X-System-Version" value:[[UIDevice currentDevice] systemVersion]];
  [getRequest addRequestHeader:@"X-Facemash-Secret" value:@"omgwtfbbq"];
  
  return getRequest;
}

+ (ASIHTTPRequest *)postRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params andPostData:(NSData *)postData withDelegate:(id)delegate {
  
  NSString *postURLString = params ? [NSString stringWithFormat:@"%@?%@", baseURLString, params] : baseURLString;
  NSURL *postURL = [NSURL URLWithString:postURLString];
  
  ASIHTTPRequest *postRequest = [ASIHTTPRequest requestWithURL:postURL];
  postRequest.shouldCompressRequestBody = YES;
  [postRequest setDelegate:delegate];
  [postRequest setNumberOfTimesToRetryOnTimeout:2];
  [postRequest setRequestMethod:@"POST"];
  [postRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [postRequest addRequestHeader:@"X-User-Id" value:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  [postRequest addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [postRequest addRequestHeader:@"X-Device-Model" value:[[UIDevice currentDevice] model]];
  [postRequest addRequestHeader:@"X-App-Version" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
  [postRequest addRequestHeader:@"X-System-Name" value:[[UIDevice currentDevice] systemName]];
  [postRequest addRequestHeader:@"X-System-Version" value:[[UIDevice currentDevice] systemVersion]];
  [postRequest addRequestHeader:@"X-Facemash-Secret" value:@"omgwtfbbq"];
  [postRequest setPostLength:[postData length]];
  [postRequest setPostBody:(NSMutableData *)postData];
  
  return postRequest;
}

+ (ASIHTTPRequest *)getFacebookRequestForMeWithDelegate:(id)delegate {
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *fields = FB_PARAMS;
  NSString *params = [NSString stringWithFormat:@"access_token=%@&fields=%@", token, fields];
  NSString *baseURLString = [NSString stringWithFormat:@"%@?%@", FB_GRAPH_ME, params];
  
  ASIHTTPRequest *meRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:baseURLString]];
  [meRequest setNumberOfTimesToRetryOnTimeout:2];
  [meRequest setDelegate:delegate];
  
  return meRequest;
}

+ (ASIHTTPRequest *)getFacebookRequestForFriendsWithDelegate:(id)delegate {
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *fields = FB_PARAMS;
  NSString *params = [NSString stringWithFormat:@"access_token=%@&fields=%@", token, fields];
  NSString *baseURLString = [NSString stringWithFormat:@"%@?%@", FB_GRAPH_FRIENDS, params];
  
  ASIHTTPRequest *friendsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:baseURLString]];
  [friendsRequest setNumberOfTimesToRetryOnTimeout:2];
  [friendsRequest setDelegate:delegate];
  
  return friendsRequest;
}

+ (ASIHTTPRequest *)getFacebookRequestForPictureWithFacebookId:(NSString *)facebookId andType:(NSString *)type withDelegate:(id)delegate {
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *params = [NSString stringWithFormat:@"access_token=%@&type=%@", token, type];
  NSString *baseURLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?%@", facebookId, params];
  
  ASIHTTPRequest *pictureRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:baseURLString]];
  [pictureRequest setNumberOfTimesToRetryOnTimeout:2];
  [pictureRequest setDelegate:delegate];
  
  return pictureRequest;
}

@end
