//
//  MashCache.m
//  Friendmash
//
//  Created by Peter Shih on 1/6/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import "MashCache.h"
#import "Constants.h"
#import "RemoteOperation.h"
#import "ASIHTTPRequest.h"
#import "RemoteRequest.h"
#import "CJSONDeserializer.h"

@interface MashCache (Private)

- (void)insertMashIntoCache;

@end

@implementation MashCache

@synthesize mashCache = _mashCache;
@synthesize recentOpponentsArray = _recentOpponentsArray;
@synthesize gender = _gender;
@synthesize gameMode = _gameMode;

@synthesize mashRequest = _mashRequest;
@synthesize leftRequest = _leftRequest;
@synthesize rightRequest = _rightRequest;

@synthesize leftUserId = _leftUserId;
@synthesize rightUserId = _rightUserId;
@synthesize leftImage = _leftImage;
@synthesize rightImage = _rightImage;

@synthesize state = _state;

@synthesize delegate = _delegate;

- (id)init {
  if ((self = [super init])) {
    _mashCache = [[NSMutableArray alloc] init];
    _recentOpponentsArray = [[NSMutableArray alloc] init];
    _gameMode = 0;
    _leftFinished = NO;
    _rightFinished = NO;
    
    _state = MashCacheStateEmpty;
  }
  return self;
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  
  // Use when fetching text data
  DLog(@"Raw response string from request: %@ => %@",request, [request responseString]);
  
  if ([request isEqual:_mashRequest]) {
    DLog(@"both request finished");
    NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
    
    self.leftUserId = [responseArray objectAtIndex:0];
    self.rightUserId = [responseArray objectAtIndex:1];
    
    self.leftRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.leftUserId andType:@"large" withDelegate:self];
    self.rightRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.rightUserId andType:@"large" withDelegate:self];
    
    [[RemoteOperation sharedInstance] addRequestToQueue:self.leftRequest];
    [[RemoteOperation sharedInstance] addRequestToQueue:self.rightRequest];
    
    DLog(@"Received matches with leftId: %@ and rightId: %@", self.leftUserId, self.rightUserId);
  } else if ([request isEqual:_leftRequest]) {
    _leftFinished = YES;
    self.leftImage = [UIImage imageWithData:[request responseData]];
    
    // If the other request also finished we are ready to insert into cache
    if (_rightFinished) {
      [self insertMashIntoCache];
    }
      
  } else if ([request isEqual:_rightRequest]) {
    _rightFinished = YES;
    self.rightImage = [UIImage imageWithData:[request responseData]];
    
    // If the other request also finished we are ready to insert into cache
    if (_leftFinished) {
      [self insertMashIntoCache];
    }
  }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Request Failed with Error: %@", [request error]);
//  if(![request isEqual:self.resultsRequest]) {
//    _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
//    [_networkErrorAlert show];
//    [_networkErrorAlert autorelease];
//  }
}

#pragma mark Handle Facebook Errors
//- (void)faceViewDidFailWithError:(NSDictionary *)errorDict {
//  if(_faceViewDidError) return;
//  _faceViewDidError = YES;
//  _oauthErrorAlert = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Your Facebook session has expired. Please login to Facebook again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
//  [_oauthErrorAlert show];
//  [_oauthErrorAlert autorelease];
//}
//
//- (void)faceViewDidFailPictureDoesNotExist {
//  if(_faceViewDidError) return;
//  _faceViewDidError = YES;
//  _fbPictureErrorAlert = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Facebook encountered an error, we promise it isn't our fault! Please try again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
//  [_fbPictureErrorAlert show];
//  [_fbPictureErrorAlert autorelease];  
//}

//NSInteger statusCode = [request responseStatusCode];
//if(statusCode > 200) {
//  DLog(@"FMVC status code not 200 in request finished, response: %@", [request responseString]);
//  // Check for a not-implemented (did not find opponents) response
//  if(statusCode == 501) {
//    [FlurryAPI logEvent:@"errorFriendmashNoOpponents"];
//    DLog(@"FMVC status code is 501 in request finished, response: %@", [request responseString]);
//    _noContentAlert = [[UIAlertView alloc] initWithTitle:@"Oh Noes!" message:@"We ran out of mashes for you. Sending you back to the home screen so you can play again." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
//    [_noContentAlert show];
//    [_noContentAlert autorelease];
//  } else {
//    [FlurryAPI logEvent:@"errorFriendmashNetworkError"];
//    DLog(@"FMVC status code not 200 or 501 in request finished, response: %@", [request responseString]);
//    _networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
//    [_networkErrorAlert show];
//    [_networkErrorAlert autorelease];
//  }
//  return;
//}

- (void)updateState {
  if ([self.mashCache count] == 0) {
    DLog(@"Cache is empty");
    self.state = MashCacheStateEmpty;
  } else if ([self.mashCache count] == 5) {
    DLog(@"Cache is full");
    self.state = MashCacheStateFull;
  } else {
    DLog(@"Cache has data");
    self.state = MashCacheStateHasData;
  }
}

#pragma mark Populate Cache
- (void)addMashToCache {  
  if([self.recentOpponentsArray count] >= 50) {
    [self.recentOpponentsArray removeAllObjects];
  }
  
  DLog(@"sending mash request");
  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@&mode=%d", self.gender, [self.recentOpponentsArray componentsJoinedByString:@","], self.gameMode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/random/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  self.mashRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.mashRequest];
}

- (void)checkMashCache {
  // If cache isn't full, we should add more
  if (self.state != MashCacheStateFull) {
    [self addMashToCache];
  }
}

- (void)insertMashIntoCache {
  // Reset left/right finished state
  _leftFinished = NO;
  _rightFinished = NO;
  
  // Populate Recents
  if(self.leftUserId) [self.recentOpponentsArray addObject:self.leftUserId];
  if(self.rightUserId) [self.recentOpponentsArray addObject:self.rightUserId];
  
  NSDictionary *cacheDict = [NSDictionary dictionaryWithObjectsAndKeys:self.leftUserId, @"leftUserId", self.rightUserId, @"rightUserId", self.leftImage, @"leftImage", self.rightImage, @"rightImage", nil];
  [self.mashCache addObject:cacheDict];
  
  // Update cache state and fire callback if necessary
  MashCacheState previousState = self.state;
  [self updateState];
  
  // Notify Delegate that we now have data
  if (self.state != MashCacheStateEmpty && previousState == MashCacheStateEmpty) {
    if (self.delegate) {
      [self.delegate retain];
      if ([self.delegate respondsToSelector:@selector(mashCacheNowHasData)]) {
        [self.delegate mashCacheNowHasData];
      }
      [self.delegate release];
    }
  }
  
  // Check cache see if we should load more
  [self checkMashCache];
}

#pragma mark Read Cache
- (NSDictionary *)retrieveMashFromCache {
  if (self.state == MashCacheStateEmpty) {
    return nil;
  }
  
  NSDictionary *mashDict = [self.mashCache objectAtIndex:0];
  [mashDict retain];
  [self.mashCache removeObject:mashDict];
  
  // If our cache was previously filled up, now we are no longer full
  // If we aren't full, we should let the cache fill up first
  // Update cache state and fire callback if necessary
  MashCacheState previousState = self.state;
  [self updateState];
  
  if (previousState == MashCacheStateFull) {
    [self checkMashCache];
  }
  
  return [mashDict autorelease];
}

#pragma mark Memory Management
- (void)dealloc {
  RELEASE_SAFELY(_mashCache);
  RELEASE_SAFELY(_recentOpponentsArray);
  RELEASE_SAFELY(_gender);
  RELEASE_SAFELY(_mashRequest);
  RELEASE_SAFELY(_leftRequest);
  RELEASE_SAFELY(_rightRequest);
  RELEASE_SAFELY(_leftUserId);
  RELEASE_SAFELY(_rightUserId);
  RELEASE_SAFELY(_leftImage);
  RELEASE_SAFELY(_rightImage);
  
  [super dealloc];
}

@end
