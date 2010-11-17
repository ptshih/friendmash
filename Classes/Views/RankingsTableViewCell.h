//
//  RankingsTableViewCell.h
//  Facemash
//
//  Created by Peter Shih on 11/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RankingsTableViewCell : UITableViewCell {
  UIImageView *_profileImageView;
  UIImageView *_likeImageView;
  UIImageView *_bulletImageView;
  UILabel *_nameLabel;
  UILabel *_rankLabel;
  UILabel *_likeLabel;
  UILabel *_streakLabel;
  UIView *_rankView;
}

@property (nonatomic, retain) UIImageView *profileImageView;
@property (nonatomic, retain) UIImageView *likeImageView;
@property (nonatomic, retain) UIImageView *bulletImageView;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *rankLabel;
@property (nonatomic, retain) UILabel *likeLabel;
@property (nonatomic, retain) UILabel *streakLabel;
@property (nonatomic, retain) UIView *rankView;

+ (void)fillCell:(RankingsTableViewCell *)cell withDictionary:(NSDictionary *)dictionary andImage:(UIImage *)profileImage;

@end
