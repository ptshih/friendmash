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

#define CACHE_SIZE 10
#define RECENTS_SIZE 50

@interface MashCache (Private)

- (void)insertMashIntoCache;
- (void)handleFacebookAndAuthErrorWithStatusCode:(NSInteger)statusCode;
- (void)errorNoMashes;
- (void)errorAuth;
- (void)errorFacebook;

@end

@implementation MashCache

@synthesize mashCache = _mashCache;
@synthesize recentOpponentsArray = _recentOpponentsArray;
@synthesize pendingRequests = _pendingRequests;
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
    _pendingRequests = [[NSMutableArray alloc] init];
    _gameMode = 0;
    _leftFinished = NO;
    _rightFinished = NO;
    _noMashesError = NO;
    _facebookError = NO;
    _authError = NO;
    
    _state = MashCacheStateEmpty;
  }
  return self;
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  NSInteger statusCode = [request responseStatusCode];

  // Use when fetching text data
  DLog(@"Raw response string from request: %@ => %@",request, [request responseString]);
  
  if ([request isEqual:_mashRequest]) {
    // Check for Error Codes
    if (statusCode > 200) {
      // ERROR
      if (statusCode == 501) {
        // No Mashes Error
        _noMashesError = YES;
        self.state = MashCacheStateNoMashes;
      } else {
        // Other Error with Friendmash Server (Just ignore it)
        // Check cache see if we should load more
        [self checkMashCache];
      }
    } else {
      // NO ERROR
      DLog(@"mash request finished");
      NSArray *responseArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
      
      self.leftUserId = [responseArray objectAtIndex:0];
      self.rightUserId = [responseArray objectAtIndex:1];
      
      self.leftRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.leftUserId andType:@"large" withDelegate:self];
      self.rightRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:self.rightUserId andType:@"large" withDelegate:self];
      
      [[RemoteOperation sharedInstance] addRequestToQueue:self.leftRequest];
      [[RemoteOperation sharedInstance] addRequestToQueue:self.rightRequest];
      
      [self.pendingRequests addObject:self.leftRequest];
      [self.pendingRequests addObject:self.rightRequest];
      
      DLog(@"Received matches with leftId: %@ and rightId: %@", self.leftUserId, self.rightUserId);
    }
  } else if ([request isEqual:_leftRequest]) {
    if (statusCode > 200) {
      // Facebook Error
      [self handleFacebookAndAuthErrorWithStatusCode:statusCode];
    } else {
      // No Error
      _leftFinished = YES;
      self.leftImage = [UIImage imageWithData:[request responseData]];
    }
    
    // If the other request also finished we are ready to insert into cache
    if (_rightFinished) {
      [self insertMashIntoCache];
    }
  } else if ([request isEqual:_rightRequest]) {
    if (statusCode > 200) {
      [self handleFacebookAndAuthErrorWithStatusCode:statusCode];
    } else {
      // No Error      
      _rightFinished = YES;
      self.rightImage = [UIImage imageWithData:[request responseData]];
    }
    
    // If the other request also finished we are ready to insert into cache
    if (_leftFinished) {
      [self insertMashIntoCache];
    }
  }
  
  // Remove request from pending requests array
  [self.pendingRequests removeObject:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Request Failed with Error: %@", [request error]);
  
  // Remove request from pending requests array
  [self.pendingRequests removeObject:request];
}

- (void)handleFacebookAndAuthErrorWithStatusCode:(NSInteger)statusCode {
  if (statusCode == 400) {
    // Auth Error
    // Immediately quit friendmash
    _authError = YES;
  } else {
    // Facebook Error (picture does not exist)
    // For now just ignore this mash and keep going
    _facebookError = YES;
  }
}

- (void)updateState {
  if (self.state == MashCacheStateNoMashes) return;
  
  if ([self.mashCache count] == 0) {
    DLog(@"Cache is empty");
    self.state = MashCacheStateEmpty;
  } else if ([self.mashCache count] == CACHE_SIZE) {
    DLog(@"Cache is full");
    self.state = MashCacheStateFull;
  } else {
    DLog(@"Cache has data");
    self.state = MashCacheStateHasData;
  }
}

#pragma mark Populate Cache
- (void)addMashToCache {
  if([self.recentOpponentsArray count] >= RECENTS_SIZE) {
    [self.recentOpponentsArray removeAllObjects];
  }
  
  DLog(@"sending mash request");
  NSString *params = [NSString stringWithFormat:@"gender=%@&recents=%@&mode=%d", self.gender, [self.recentOpponentsArray componentsJoinedByString:@","], self.gameMode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/random/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  self.mashRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.mashRequest];
  [self.pendingRequests addObject:self.mashRequest];
}

- (void)checkMashCache {
  if (self.state == MashCacheStateNoMashes) {
    // No more mashes, stop loading
  } else if (self.state != MashCacheStateFull) {
    // If cache isn't full, we should add more
    [self addMashToCache];
  }
}

- (void)insertMashIntoCache {
  // Reset left/right finished state
  _leftFinished = NO;
  _rightFinished = NO;

  if (_authError) {
    // If Auth error, immediately quit
    [self errorAuth];
    return;
  } else if (_facebookError) {
    // If facebook error got triggered, ignore this mash and continue
    _facebookError = NO;
  } else {
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
  }
  
  // Check cache see if we should load more
  [self checkMashCache];
}

#pragma mark Read Cache
- (NSDictionary *)retrieveMashFromCache {
  if (self.state == MashCacheStateNoMashes && [self.mashCache count] == 0) {
    // Throw error showing no mashes
    [self errorNoMashes];
    return nil;
  } else if (self.state == MashCacheStateEmpty) {
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

#pragma mark Error Handling
- (void)errorNoMashes {
  if (self.delegate) {
    [self.delegate retain];
    if ([self.delegate respondsToSelector:@selector(mashCacheNoMashesError)]) {
      [self.delegate mashCacheNoMashesError];
    }
    [self.delegate release];
  } 
}

- (void)errorFacebook {
  if (self.delegate) {
    [self.delegate retain];
    if ([self.delegate respondsToSelector:@selector(mashCacheFacebookError)]) {
      [self.delegate mashCacheFacebookError];
    }
    [self.delegate release];
  } 
}

- (void)errorAuth {
  if (self.delegate) {
    [self.delegate retain];
    if ([self.delegate respondsToSelector:@selector(mashCacheAuthError)]) {
      [self.delegate mashCacheAuthError];
    }
    [self.delegate release];
  } 
}

#pragma mark Memory Management
- (void)dealloc {
  for (ASIHTTPRequest *pendingRequest in self.pendingRequests) {
    [pendingRequest clearDelegatesAndCancel];
  }
  [self.pendingRequests removeAllObjects];
  
  RELEASE_SAFELY(_mashCache);
  RELEASE_SAFELY(_recentOpponentsArray);
  RELEASE_SAFELY(_pendingRequests);
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
