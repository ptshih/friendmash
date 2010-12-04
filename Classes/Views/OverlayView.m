//
//  OverlayView.m
//  Friendmash
//
//  Created by Peter Shih on 12/4/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

@synthesize dismissButton = _dismissButton;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  if(_dismissButton) [_dismissButton release];
  [super dealloc];
}

@end
