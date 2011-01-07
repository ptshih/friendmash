//
//  RemoteOperation.m
//  Friendmash
//
//  Created by Peter Shih on 1/6/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import "RemoteOperation.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Constants.h"

static RemoteOperation *_sharedInstance = nil;

@implementation RemoteOperation

@synthesize networkQueue = _networkQueue;
@synthesize delegate = _delegate;


#pragma mark Singleton methods
+ (void)initialize {
	@synchronized(self) {
    if (_sharedInstance == nil) {
			_sharedInstance = [[RemoteOperation alloc] init];
      _sharedInstance.networkQueue = [[ASINetworkQueue queue] retain];
      _sharedInstance.networkQueue.delegate = _sharedInstance;
      [_sharedInstance.networkQueue setShouldCancelAllRequestsOnFailure:NO];
//      [_sharedInstance.networkQueue setRequestDidFinishSelector:@selector(requestFinished:)];
//      [_sharedInstance.networkQueue setRequestDidFailSelector:@selector(requestFailed:)];
      [_sharedInstance.networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
		}
  }
}

#pragma mark Accessor for Shared Instance
+ (RemoteOperation *)sharedInstance {
  return _sharedInstance;
}

#pragma mark Class Methods
- (void)addRequestToQueue:(ASIHTTPRequest *)request {
  [_sharedInstance.networkQueue addOperation:request];
  [_sharedInstance.networkQueue go];
}

- (void)cancelAllRequests {
  [_sharedInstance.networkQueue cancelAllOperations];
}

#pragma mark ASIHTTPRequest
- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark Memory Management
+ (id)allocWithZone:(NSZone *)zone {
  @synchronized(self) {
    if (_sharedInstance == nil) {
      _sharedInstance = [super allocWithZone:zone];
      return _sharedInstance;  // assignment and return on first allocation
    }
  }
  return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (id)retain {
  return self;
}

- (unsigned)retainCount {
  return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
  // do nothing
}

- (id)autorelease {
  return self;
}

@end
