//
//  ImageCache.m
//  Friendmash
//
//  Created by Peter Shih on 11/9/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "ImageCache.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "CJSONDeserializer.h"
#import "Constants.h"

@implementation ImageCache

@synthesize imageCache = _imageCache;
@synthesize pendingRequests = _pendingRequests;
@synthesize networkQueue = _networkQueue;
@synthesize delegate;

- (id)init {
  if ((self = [super init])) {
    _imageCache = [[NSMutableDictionary alloc] init];
    _pendingRequests = [[NSMutableDictionary alloc] init];
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
  }
  return self;
}

- (void)resetCache {
  for (ASIHTTPRequest *pendingRequest in [self.pendingRequests allValues]) {
    [pendingRequest clearDelegatesAndCancel];
  }
  [self.imageCache removeAllObjects];
  [self.pendingRequests removeAllObjects];
}

- (void)cacheImageWithURL:(NSURL *)url forIndexPath:(NSIndexPath *)indexPath {
  ASIHTTPRequest *rankingsRequest = [ASIHTTPRequest requestWithURL:url];
  [rankingsRequest setNumberOfTimesToRetryOnTimeout:2];
  [self.pendingRequests setObject:rankingsRequest forKey:indexPath];
  [self.networkQueue addOperation:rankingsRequest];
  [self.networkQueue go];
}

- (void)cacheImageWithRequest:(ASIHTTPRequest *)request forIndexPath:(NSIndexPath *)indexPath {
  [self.pendingRequests setObject:request forKey:indexPath];
  [self.networkQueue addOperation:request];
  [self.networkQueue go];
}

- (UIImage *)getImageForIndexPath:(NSIndexPath *)indexPath {
  return [self.imageCache objectForKey:indexPath];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // This is on the main thread
  
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    if(statusCode == 400) {
      // FB TOKEN EXPIRED!!!
      // NOTE: We should technically tell the user to login again, code not complete here
      // NSDictionary *errorDict = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil] objectForKey:@"error"];
      // oauth token expired
    }
  } else {
    if([[self.pendingRequests allKeysForObject:request] count] > 0) {
      NSIndexPath *indexPath = [[self.pendingRequests allKeysForObject:request] objectAtIndex:0];
      [self.pendingRequests removeObjectForKey:indexPath];
      [self.imageCache setObject:[UIImage imageWithData:[request responseData]] forKey:indexPath];
      if([delegate respondsToSelector:@selector(imageDidLoad:)]) {
        [delegate imageDidLoad:indexPath];
      }
    }
  }
  
  DLog(@"Request finished successfully");
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  DLog(@"Request Failed with Error: %@", [request error]);
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

- (void)dealloc {
  [self resetCache];
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  
  RELEASE_SAFELY(_networkQueue);
  RELEASE_SAFELY(_pendingRequests);
  RELEASE_SAFELY(_imageCache);

  [super dealloc];
}


@end
