/*
 *  RemoteOperationDelegate.h
 *  Friendmash
 *
 *  Created by Peter Shih on 1/6/11.
 *  Copyright 2011 Seven Minute Apps. All rights reserved.
 *
 */

@class RemoteOperation;
@class ASIHTTPRequest;
@class ASINetworkQueue;

@protocol RemoteOperationDelegate <NSObject>
@optional
- (void)remoteOperation:(RemoteOperation *)operation didFinishRequest:(ASIHTTPRequest *)request;
- (void)remoteOperation:(RemoteOperation *)operation didFailRequest:(ASIHTTPRequest *)request;
- (void)remoteOperation:(RemoteOperation *)operation didFinishQueue:(ASINetworkQueue *)queue;
@end