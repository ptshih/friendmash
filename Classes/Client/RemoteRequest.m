//
//  RemoteRequest.m
//  Friendmash
//
//  Created by Peter Shih on 11/10/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "RemoteRequest.h"
#import "ASIHTTPRequest.h"
#import "NSString+Util.h"
#import "HashValue.h"
#import "Constants.h"

static NSString *_secretString = nil;

@implementation RemoteRequest

+ (void)load {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // Calculate SHA256 hash for secret
  HashValue *secretHash = [HashValue sha256HashWithData:[@"omgwtfbbqflylikeag6" dataUsingEncoding:NSUTF8StringEncoding]];
  _secretString = [[secretHash description] retain];
  [pool drain];
}

+ (ASIHTTPRequest *)getRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params withDelegate:(id)delegate {
  NSString *getURLString = params ? [NSString stringWithFormat:@"%@?%@", baseURLString, params] : baseURLString;
  NSURL *getURL = [NSURL URLWithString:getURLString];
  
  ASIHTTPRequest *getRequest = [ASIHTTPRequest requestWithURL:getURL];
  [getRequest setDelegate:delegate];
  [getRequest setNumberOfTimesToRetryOnTimeout:2];
  [getRequest setAllowCompressedResponse:YES];
  [getRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [getRequest addRequestHeader:@"Accept" value:@"application/json"];
  [getRequest setRequestMethod:@"GET"];
  [getRequest addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [getRequest addRequestHeader:@"X-Device-Model" value:[[UIDevice currentDevice] model]];
  [getRequest addRequestHeader:@"X-App-Version" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
  [getRequest addRequestHeader:@"X-System-Name" value:[[UIDevice currentDevice] systemName]];
  [getRequest addRequestHeader:@"X-System-Version" value:[[UIDevice currentDevice] systemVersion]];
  [getRequest addRequestHeader:@"X-Connection-Type" value:[NSString stringWithFormat:@"%d",APP_DELEGATE.netStatus]];
  [getRequest addRequestHeader:@"X-User-Language" value:USER_LANGUAGE];
  [getRequest addRequestHeader:@"X-User-Locale" value:USER_LOCALE];
  if(APP_DELEGATE.sessionKey) [getRequest addRequestHeader:@"X-Session-Key" value:APP_DELEGATE.sessionKey];
  if(APP_DELEGATE.currentUserId) [getRequest addRequestHeader:@"X-User-Id" value:APP_DELEGATE.currentUserId];
  [getRequest addRequestHeader:@"X-Friendmash-Secret" value:_secretString];
  
  return getRequest;
}

+ (ASIHTTPRequest *)postRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params andPostData:(NSData *)postData isGzip:(BOOL)isGzip withDelegate:(id)delegate {
  NSString *postURLString = params ? [NSString stringWithFormat:@"%@?%@", baseURLString, params] : baseURLString;
  NSURL *postURL = [NSURL URLWithString:postURLString];
  
  ASIHTTPRequest *postRequest = [ASIHTTPRequest requestWithURL:postURL];

  [postRequest setDelegate:delegate];
  [postRequest setNumberOfTimesToRetryOnTimeout:2];
  [postRequest setRequestMethod:@"POST"];
  [postRequest setShouldCompressRequestBody:isGzip]; // GZIP the postData
  [postRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [postRequest addRequestHeader:@"Accept" value:@"application/json"];
  [postRequest addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [postRequest addRequestHeader:@"X-Device-Model" value:[[UIDevice currentDevice] model]];
  [postRequest addRequestHeader:@"X-App-Version" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
  [postRequest addRequestHeader:@"X-System-Name" value:[[UIDevice currentDevice] systemName]];
  [postRequest addRequestHeader:@"X-System-Version" value:[[UIDevice currentDevice] systemVersion]];
  [postRequest addRequestHeader:@"X-Connection-Type" value:[NSString stringWithFormat:@"%d",APP_DELEGATE.netStatus]];
  [postRequest addRequestHeader:@"X-User-Language" value:USER_LANGUAGE];
  [postRequest addRequestHeader:@"X-User-Locale" value:USER_LOCALE];
  if(APP_DELEGATE.sessionKey) [postRequest addRequestHeader:@"X-Session-Key" value:APP_DELEGATE.sessionKey];
  if(APP_DELEGATE.currentUserId) [postRequest addRequestHeader:@"X-User-Id" value:APP_DELEGATE.currentUserId];
  [postRequest addRequestHeader:@"X-Friendmash-Secret" value:_secretString];
//  [postRequest setPostLength:[postData length]];
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
  [meRequest setAllowCompressedResponse:YES];
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
  [friendsRequest setAllowCompressedResponse:YES];
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

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
  return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}

/**
 * Generate get URL
 */
+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {
  
  NSURL* parsedURL = [NSURL URLWithString:baseUrl];
  NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
  
  NSMutableArray* pairs = [NSMutableArray array];
  for (NSString* key in [params keyEnumerator]) {
    if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
        ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
      if ([httpMethod isEqualToString:@"GET"]) {
        DLog(@"can not use GET to upload a file");
      }
      continue;
    }
    
    NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL, /* allocator */
                                                                                  (CFStringRef)[params objectForKey:key],
                                                                                  NULL, /* charactersToLeaveUnescaped */
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8);
    
    [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    [escaped_value release];
  }
  NSString* query = [pairs componentsJoinedByString:@"&"];
  
  return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

@end
