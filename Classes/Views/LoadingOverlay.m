//
//  LoadingOverlay.m
//  Wikinvest
//
//  Created by Peter Shih on 2/18/10.
//  Copyright 2010 Wikinvest. All rights reserved.
//

#import "LoadingOverlay.h"

@implementation LoadingOverlay

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      self.backgroundColor = [UIColor clearColor];
      self.alpha = 1.0;
        
      UIView *backgroundView = [[UIView alloc] initWithFrame:self.frame];
      backgroundView.backgroundColor = [UIColor blackColor];
      backgroundView.center = self.center;
      backgroundView.alpha = 0.25;
      [self addSubview:backgroundView];
      [backgroundView release];
      
      UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
      activityIndicator.center = self.center;
      [activityIndicator startAnimating];
      [self addSubview:activityIndicator];
      [activityIndicator release];
    }
    return self;
}


//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//}


- (void)dealloc {
    [super dealloc];
}


@end
