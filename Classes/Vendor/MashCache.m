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

@implementation MashCache

@synthesize mashCache = _mashCache;

- (id)init {
  if ((self = [super init])) {
    _mashCache = [[NSMutableDictionary alloc] init];
  }
  return self;
}


#pragma mark RemoteOperationDelegate
- (void)remoteOperation:(RemoteOperation *)operation didFinishRequest:(ASIHTTPRequest *)request {
  
}

- (void)dealloc {
  RELEASE_SAFELY(_mashCache);
  [super dealloc];
}

@end
