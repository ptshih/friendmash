//
//  RankingsTableViewCell.m
//  Facemash
//
//  Created by Peter Shih on 11/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RankingsTableViewCell.h"
#import "UIView+Additions.h"
#import "NSObject+ConvenienceMethods.h"
#import "NSString+ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>

#define PROFILE_IMAGE_MARGIN_X 10.0
#define PROFILE_IMAGE_MARGIN_Y 5.0
#define PROFILE_IMAGE_SIZE 50.0

@implementation RankingsTableViewCell

@synthesize profileImageView = _profileImageView;
@synthesize nameLabel = _nameLabel;
@synthesize rankLabel = _rankLabel;
@synthesize scoreLabel = _scoreLabel;
@synthesize winLossLabel = _winLossLabel;
@synthesize rankView = _rankView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Disable selection for now
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(PROFILE_IMAGE_MARGIN_X, PROFILE_IMAGE_MARGIN_Y, PROFILE_IMAGE_SIZE, PROFILE_IMAGE_SIZE)];
    self.profileImageView.layer.cornerRadius = 5.0;
    self.profileImageView.layer.masksToBounds = YES;
    _nameLabel = [[UILabel alloc] init];
    _rankLabel = [[UILabel alloc] init];
    _scoreLabel = [[UILabel alloc] init];
    _winLossLabel = [[UILabel alloc] init];
    _rankView = [[UIView alloc] init];
    
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.rankLabel.backgroundColor = [UIColor clearColor];
    self.scoreLabel.backgroundColor = [UIColor clearColor];
    self.winLossLabel.backgroundColor = [UIColor clearColor];
    
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17.0];
    
    self.rankLabel.textAlignment = UITextAlignmentCenter;
    self.rankLabel.font = [UIFont boldSystemFontOfSize:17.0];
//    self.rankLabel.font = [UIFont fontWithName:@"Lucida Grande" size:18.0];

    self.rankView.backgroundColor = [UIColor clearColor];
    self.rankView.frame = CGRectMake(0, 0, 52, 50);
    UIImageView *rankStarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favorite_star.png"]];
    rankStarView.frame = self.rankView.frame;
    self.rankLabel.frame = self.rankView.frame;
    [self.rankView addSubview:rankStarView];
    [self.rankView addSubview:self.rankLabel];
    [rankStarView release];
    
    [self.contentView addSubview:self.profileImageView];
    [self.contentView addSubview:self.nameLabel];
//    [self.contentView addSubview:self.scoreLabel];
    [self.contentView addSubview:self.winLossLabel];
    [self.contentView addSubview:self.rankView];
    
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.profileImageView.image = nil;
  self.nameLabel.text = nil;
  self.rankLabel.text = nil;
  self.scoreLabel.text = nil;
  self.winLossLabel.text = nil;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.profileImageView.left = PROFILE_IMAGE_MARGIN_X;
  self.profileImageView.top = PROFILE_IMAGE_MARGIN_Y;
  
  CGFloat leftTop = self.profileImageView.right + PROFILE_IMAGE_MARGIN_X;
  CGFloat leftBot = self.profileImageView.right + PROFILE_IMAGE_MARGIN_X;
  
  CGFloat topY = 8.0;
  CGFloat botY = 32.0;
  
  self.nameLabel.left = leftTop;
  self.rankLabel.left = leftTop;
  self.winLossLabel.left = leftBot;
  self.scoreLabel.left = leftBot;
  
  self.nameLabel.top = topY;
  self.rankLabel.top = topY;
  self.winLossLabel.top = botY;
  self.scoreLabel.top = botY;
  
  CGFloat textWidthTop = self.contentView.width - leftTop - 10;
  CGSize textSizeTop = CGSizeMake(textWidthTop, INT_MAX);
  
  CGFloat textWidthBot = self.contentView.width - leftBot - 10;
  CGSize textSizeBot = CGSizeMake(textWidthBot, INT_MAX);
  
  // Top
  CGSize nameSize = [self.nameLabel.text sizeWithFont:self.nameLabel.font constrainedToSize:textSizeTop lineBreakMode:UILineBreakModeWordWrap];
  self.nameLabel.height = nameSize.height;
  self.nameLabel.width = nameSize.width;
//  leftTop += self.nameLabel.width + 10;
//  textWidthTop -= self.nameLabel.width + 10;
//  textSizeTop = CGSizeMake(textWidthTop, INT_MAX);
  
//  CGSize rankSize = [self.rankLabel.text sizeWithFont:self.rankLabel.font constrainedToSize:textSizeTop lineBreakMode:UILineBreakModeWordWrap];
//  self.rankLabel.height = rankSize.height;
//  self.rankLabel.width = rankSize.width;
//  self.rankLabel.left = self.contentView.width - 10.0 - self.rankLabel.width;
  
  
  // Bottom
  CGSize winLossSize = [self.winLossLabel.text sizeWithFont:self.winLossLabel.font constrainedToSize:textSizeBot lineBreakMode:UILineBreakModeWordWrap];
  self.winLossLabel.height = winLossSize.height;
  self.winLossLabel.width = winLossSize.width;
//  leftBot += self.winLossLabel.width + 10;
//  textWidthBot -= self.nameLabel.width + 10;
//  textSizeBot = CGSizeMake(textWidthBot, INT_MAX);
  
//  CGSize scoreSize = [self.scoreLabel.text sizeWithFont:self.scoreLabel.font constrainedToSize:textSizeBot lineBreakMode:UILineBreakModeWordWrap];
//  self.scoreLabel.height = scoreSize.height;
//  self.scoreLabel.width = scoreSize.width;
//  self.scoreLabel.left = self.contentView.width - 10.0 - self.scoreLabel.width;
  
  // Star
  self.rankView.left = self.contentView.width - 10.0 - self.rankView.width;
  self.rankView.top = 5.0;
  
  CGSize rankSize = [self.rankLabel.text sizeWithFont:self.rankLabel.font constrainedToSize:CGSizeMake(52, 50) lineBreakMode:UILineBreakModeWordWrap];
  self.rankLabel.height = rankSize.height;
  self.rankLabel.width = rankSize.width;
  self.rankLabel.center = CGPointMake(27, 27);
  
}

+ (void)fillCell:(RankingsTableViewCell *)cell withDictionary:(NSDictionary *)dictionary andImage:(UIImage *)profileImage {
  cell.profileImageView.image = profileImage;
  cell.nameLabel.text = [[dictionary objectForKey:@"full_name"] notNil] ? [dictionary objectForKey:@"full_name"] : @"Anonymous";
  cell.rankLabel.text = [NSString stringWithFormat:@"%@", [[dictionary objectForKey:@"rank"] stringValue]];
//  cell.scoreLabel.text = [NSString stringWithFormat:@"Score: %@", [[dictionary objectForKey:@"score"] stringValue]];
  cell.winLossLabel.text = [NSString stringWithFormat:@"Likes: %@  Dislikes: %@  Score: %@", [[dictionary objectForKey:@"wins"] stringValue], [[dictionary objectForKey:@"losses"] stringValue], [[dictionary objectForKey:@"score"] stringValue]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {    
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state.
}


- (void)dealloc {
  [_profileImageView release];
  [_nameLabel release];
  [_rankLabel release];
  [_scoreLabel release];
  [_winLossLabel release];
  [_rankView release];
  [super dealloc];
}

@end
