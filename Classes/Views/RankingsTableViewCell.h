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
  UILabel *_nameLabel;
  UILabel *_rankLabel;
  UILabel *_scoreLabel;
  UILabel *_winLossLabel;
  UIView *_rankView;
}

@property (nonatomic, retain) UIImageView *profileImageView;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *rankLabel;
@property (nonatomic, retain) UILabel *scoreLabel;
@property (nonatomic, retain) UILabel *winLossLabel;
@property (nonatomic, retain) UIView *rankView;

+ (void)fillCell:(RankingsTableViewCell *)cell withDictionary:(NSDictionary *)dictionary andImage:(UIImage *)profileImage;

@end
