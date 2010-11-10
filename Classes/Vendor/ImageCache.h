//
//  ImageCache.h
//  Facemash
//
//  Created by Peter Shih on 11/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageCacheDelegate <NSObject>
@required
- (void)imageDidLoad:(NSIndexPath *)indexPath;
@end

@class ASINetworkQueue;

@interface ImageCache : NSObject {
  NSMutableDictionary *_imageCache;
  NSMutableDictionary *_pendingRequests;
  ASINetworkQueue *_networkQueue;
  id <ImageCacheDelegate> delegate;
}

@property (nonatomic, retain) NSMutableDictionary *imageCache;
@property (nonatomic, retain) NSMutableDictionary *pendingRequests;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, assign) id <ImageCacheDelegate> delegate;

- (void)resetCache;
- (void)cacheImageWithURL:(NSURL *)url forIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)getImageForIndexPath:(NSIndexPath *)indexPath;

@end
