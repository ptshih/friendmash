//
//  ThumbsView.h
//  Friendmash
//
//  Created by Peter Shih on 12/3/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
  ThumbsLike = 0,
  ThumbsDislike = 1,
} ThumbsType;


@interface ThumbsView : UIView {
  IBOutlet UIImageView *_thumbImageView;
}

@property (nonatomic, retain) UIImageView *thumbImageView;

- (void)setState:(ThumbsType)type;

@end
