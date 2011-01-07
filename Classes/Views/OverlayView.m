//
//  OverlayView.m
//  Friendmash
//
//  Created by Peter Shih on 12/4/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "OverlayView.h"
#import "Constants.h"

@implementation OverlayView

@synthesize dismissButton = _dismissButton;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_dismissButton);
  [super dealloc];
}

@end
