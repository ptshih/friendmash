//
//  MashCache.h
//  Friendmash
//
//  Created by Peter Shih on 1/6/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteOperationDelegate.h"

@interface MashCache : NSObject <RemoteOperationDelegate> {
  NSMutableArray *_mashCache;
  
}

@property (retain) NSMutableArray *mashCache; // Needs to be atomic, two threads accessing

@end
