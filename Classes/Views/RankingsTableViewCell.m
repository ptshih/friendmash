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

static UIImage *_starImage;
static UIImage *_likeImage;
static UIImage *_bulletImage;

@implementation RankingsTableViewCell

@synthesize profileImageView = _profileImageView;
@synthesize likeImageView = _likeImageView;
@synthesize bulletImageView = _bulletImageView;
@synthesize nameLabel = _nameLabel;
@synthesize rankLabel = _rankLabel;
@synthesize likeLabel = _likeLabel;
@synthesize streakLabel = _streakLabel;
@synthesize rankView = _rankView;

+ (void)initialize {
  _starImage = [[UIImage imageNamed:@"favorite_star.png"] retain];
  _likeImage = [[UIImage imageNamed:@"likes.png"] retain];
  _bulletImage = [[UIImage imageNamed:@"bullet.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Disable selection for now
    // self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(PROFILE_IMAGE_MARGIN_X, PROFILE_IMAGE_MARGIN_Y, PROFILE_IMAGE_SIZE, PROFILE_IMAGE_SIZE)];
    _likeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 18)];
    _bulletImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 18)];
    self.likeImageView.image = _likeImage;
    self.bulletImageView.image = _bulletImage;
    self.bulletImageView.contentMode = UIViewContentModeCenter;
    self.profileImageView.layer.cornerRadius = 5.0;
    self.profileImageView.layer.masksToBounds = YES;
    _nameLabel = [[UILabel alloc] init];
    _rankLabel = [[UILabel alloc] init];
    _likeLabel = [[UILabel alloc] init];
    _streakLabel = [[UILabel alloc] init];
    _rankView = [[UIView alloc] init];
    
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.rankLabel.backgroundColor = [UIColor clearColor];
    self.likeLabel.backgroundColor = [UIColor clearColor];
    self.streakLabel.backgroundColor = [UIColor clearColor];
    
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.rankLabel.textAlignment = UITextAlignmentCenter;
    self.rankLabel.font = [UIFont boldSystemFontOfSize:17.0];

    self.rankView.backgroundColor = [UIColor clearColor];
    self.rankView.frame = CGRectMake(0, 0, 52, 50);
    UIImageView *rankStarView = [[UIImageView alloc] initWithImage:_starImage];
    rankStarView.frame = self.rankView.frame;
    self.rankLabel.frame = self.rankView.frame;
    [self.rankView addSubview:rankStarView];
    [self.rankView addSubview:self.rankLabel];
    [rankStarView release];
    
    [self.contentView addSubview:self.profileImageView];
    [self.contentView addSubview:self.likeImageView];
    [self.contentView addSubview:self.bulletImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.likeLabel];
    [self.contentView addSubview:self.streakLabel];
    [self.contentView addSubview:self.rankView];
    
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.profileImageView.image = nil;
  self.nameLabel.text = nil;
  self.rankLabel.text = nil;
  self.likeLabel.text = nil;
  self.streakLabel.text = nil;
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
  self.nameLabel.top = topY;
  self.rankLabel.top = topY;
  
  
  CGFloat textWidthTop = self.contentView.width - leftTop - 10;
  CGSize textSizeTop = CGSizeMake(textWidthTop, INT_MAX);
  
  // Top
  CGSize nameSize = [self.nameLabel.text sizeWithFont:self.nameLabel.font constrainedToSize:textSizeTop lineBreakMode:UILineBreakModeWordWrap];
  self.nameLabel.height = nameSize.height;
  self.nameLabel.width = nameSize.width;
  
  // Like Button
  self.likeImageView.left = leftBot;
  self.likeImageView.top = botY;
  
  leftBot = self.likeImageView.right + 7.0;
  
  self.likeLabel.left = leftBot;
  self.likeLabel.top = botY;
  
  CGFloat textWidthBot = self.contentView.width - leftBot - 10.0;
  CGSize textSizeBot = CGSizeMake(textWidthBot, INT_MAX);
  
  // Bottom
  CGSize likeSize = [self.likeLabel.text sizeWithFont:self.likeLabel.font constrainedToSize:textSizeBot lineBreakMode:UILineBreakModeWordWrap];
  self.likeLabel.height = likeSize.height;
  self.likeLabel.width = likeSize.width;
  
  leftBot = self.likeLabel.right;
  
  // Bullet Button
  self.bulletImageView.left = leftBot;
  self.bulletImageView.top = botY + 2.0;
  
  leftBot = self.bulletImageView.right + 3.0;
  
  textWidthBot = self.contentView.width - leftBot - 10.0;
  textSizeBot = CGSizeMake(textWidthBot, INT_MAX);
  
  self.streakLabel.left = leftBot;
  self.streakLabel.top = botY;
  
  CGSize streakSize = [self.streakLabel.text sizeWithFont:self.streakLabel.font constrainedToSize:textSizeBot lineBreakMode:UILineBreakModeWordWrap];
  self.streakLabel.height = streakSize.height;
  self.streakLabel.width = streakSize.width;
  
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
  if([[dictionary objectForKey:@"first_name"] notNil]) {
    NSString *lastInitial = [[dictionary objectForKey:@"last_name"] substringToIndex:1];
    if([lastInitial length] == [[dictionary objectForKey:@"last_name"] length]) {
      lastInitial = @"";
    }
    cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [dictionary objectForKey:@"first_name"], lastInitial];
  } else {
    cell.nameLabel.text = @"Anonymous";
  }

//  cell.nameLabel.text = [[dictionary objectForKey:@"full_name"] notNil] ? [dictionary objectForKey:@"full_name"] : @"Anonymous";
  cell.rankLabel.text = [NSString stringWithFormat:@"%@", [[dictionary objectForKey:@"rank"] stringValue]];
  cell.likeLabel.text = [NSString stringWithFormat:@"%@ Likes", [[dictionary objectForKey:@"wins"] stringValue]];
  cell.streakLabel.text = [NSString stringWithFormat:@"Longest Like Streak: %@", [[dictionary objectForKey:@"win_streak_max"] stringValue]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {    
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state.
}

- (void)dealloc {
  [_profileImageView release];
  [_likeImageView release];
  [_bulletImageView release];
  [_nameLabel release];
  [_rankLabel release];
  [_likeLabel release];
  [_streakLabel release];
  [_rankView release];
  [super dealloc];
}

@end
