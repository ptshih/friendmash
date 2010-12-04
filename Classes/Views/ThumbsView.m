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

+ (void)initialize {
  if (isDeviceIPad()) {
    _thumbLikeImage = [UIImage imageNamed:@"large_like_iPad.png"];
    _thumbDislikeImage = [UIImage imageNamed:@"large_dislike_iPad.png"];
  } else {
    _thumbLikeImage = [UIImage imageNamed:@"large_like.png"];
    _thumbDislikeImage = [UIImage imageNamed:@"large_dislike.png"];
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
  if(_thumbImageView) [_thumbImageView release];
  [super dealloc];
}

@end
