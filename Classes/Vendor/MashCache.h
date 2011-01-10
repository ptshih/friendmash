//
//  MashCache.h
//  Friendmash
//
//  Created by Peter Shih on 1/6/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MashCacheDelegate.h"
#import "Reachability.h"

typedef enum {
  MashCacheStateEmpty = 0,
  MashCacheStateHasData = 1,
  MashCacheStateFull = 2,
  MashCacheStateNoMashes = 3
} MashCacheState;

@class ASIHTTPRequest;

@interface MashCache : NSObject {
  NSMutableArray *_mashCache;
  NSMutableArray *_recentOpponentsArray;
  NSMutableArray *_pendingRequests;
  NSString *_gender;
  NSInteger _gameMode;
  
  ASIHTTPRequest *_mashRequest;
  ASIHTTPRequest *_leftRequest;
  ASIHTTPRequest *_rightRequest;
  NSString *_leftUserId;
  NSString *_rightUserId;
  UIImage *_leftImage;
  UIImage *_rightImage;
  
  BOOL _leftFinished;
  BOOL _rightFinished;
  
  BOOL _noMashesError;
  BOOL _facebookError;
  BOOL _authError;
  
  MashCacheState _state;
  
  NetworkStatus _netStatus;
  
  id <MashCacheDelegate> _delegate;
}

@property (retain) NSMutableArray *mashCache; // Needs to be atomic, two threads accessing
@property (nonatomic,retain) NSMutableArray *recentOpponentsArray;
@property (nonatomic,retain) NSMutableArray *pendingRequests;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, assign) NSInteger gameMode;

@property (nonatomic, retain) ASIHTTPRequest *mashRequest;
@property (nonatomic, retain) ASIHTTPRequest *leftRequest;
@property (nonatomic, retain) ASIHTTPRequest *rightRequest;

@property (nonatomic, retain) NSString *leftUserId;
@property (nonatomic, retain) NSString *rightUserId;
@property (nonatomic, retain) UIImage *leftImage;
@property (nonatomic, retain) UIImage *rightImage;

@property (nonatomic, assign) MashCacheState state;

@property (nonatomic, assign) NetworkStatus netStatus;

@property (nonatomic, assign) id <MashCacheDelegate> delegate;

- (void)checkMashCache;

- (NSDictionary *)retrieveMashFromCache;

@end
