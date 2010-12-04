//
//  OverlayView.h
//  Friendmash
//
//  Created by Peter Shih on 12/4/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OverlayView : UIView {
  IBOutlet UIButton *_dismissButton;
}

@property (nonatomic, retain) UIButton *dismissButton;

@end
