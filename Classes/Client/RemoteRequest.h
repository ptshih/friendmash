//
//  RemoteRequest.h
//  Facemash
//
//  Created by Peter Shih on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;

@interface RemoteRequest : NSObject {

}

/*
 * GET
 */
+ (ASIHTTPRequest *)getRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params withDelegate:(id)delegate;

/*
 * POST
 */
+ (ASIHTTPRequest *)postRequestWithBaseURLString:(NSString *)baseURLString andParams:(NSString *)params andPostData:(NSData *)postData withDelegate:(id)delegate;

/*
 * Facebook
 */
+ (ASIHTTPRequest *)getFacebookRequestForMeWithDelegate:(id)delegate;

+ (ASIHTTPRequest *)getFacebookRequestForFriendsWithDelegate:(id)delegate;

+ (ASIHTTPRequest *)getFacebookRequestForPictureWithFacebookId:(NSString *)facebookId andType:(NSString *)type withDelegate:(id)delegate;

@end
