//
//  ThumbsView.m
//  Friendmash
//
//  Created by Peter Shih on 12/3/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "ThumbsView.h"
#import "Constants.h"

static UIImage *_thumbLikeImage = nil;
static UIImage *_thumbDislikeImage = nil;

@implementation ThumbsView

@synthesize thumbImageView = thumbImageView;

+ (void)initialize {
  if (isDeviceIPad()) {
    _thumbLikeImage = [[UIImage imageNamed:@"large_like_iPad.png"] retain];
    _thumbDislikeImage = [[UIImage imageNamed:@"large_dislike_iPad.png"] retain];
  } else {
    _thumbLikeImage = [[UIImage imageNamed:@"large_like.png"] retain];
    _thumbDislikeImage = [[UIImage imageNamed:@"large_dislike.png"] retain];
  }
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}

- (void)setState:(ThumbsType)type {
  if (type == ThumbsLike) {
    _thumbImageView.image = _thumbLikeImage;
  } else {
    _thumbImageView.image = _thumbDislikeImage;
  }
}

- (void)dealloc {
  RELEASE_SAFELY(_thumbImageView);
  [super dealloc];
}

@end
