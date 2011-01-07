//
//  RemoteOperation.h
//  Friendmash
//
//  Created by Peter Shih on 1/6/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteOperationDelegate.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface RemoteOperation : NSObject {
  ASINetworkQueue *_networkQueue;
  NSMutableArray *_pendingRequests;
  id <RemoteOperationDelegate> _delegate;
}

@property (retain) ASINetworkQueue *networkQueue; // Needs to be atomic, multi-threaded
@property (nonatomic, retain) NSMutableArray *pendingRequests; // An array of pending ASIHTTPRequest objects
@property (nonatomic, assign) id <RemoteOperationDelegate> delegate;

- (void)addRequestToQueue:(ASIHTTPRequest *)request;
- (void)cancelAllRequests;

@end
