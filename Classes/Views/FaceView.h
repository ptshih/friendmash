//
//  FaceView.h
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FaceView : UIView {
  UIView *_canvas;
  CGPoint defaultOrigin;
  CGPoint myCenter;
  CGPoint touchOrigin;
  BOOL _isLeft;
}

@property (nonatomic, retain) UIView *canvas;
@property (nonatomic, assign) BOOL isLeft;

- (void)setDefaultPosition;

@end
