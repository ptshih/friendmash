/*
 *  MashCacheDelegate.h
 *  Friendmash
 *
 *  Created by Peter Shih on 1/7/11.
 *  Copyright 2011 Seven Minute Apps. All rights reserved.
 *
 */

@protocol MashCacheDelegate <NSObject>
@required
- (void)mashCacheNowHasData;
@optional
- (void)mashCacheNoMashesError;
- (void)mashCacheFacebookError;
- (void)mashCacheAuthError;
@end