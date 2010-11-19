//
//  AboutViewController.m
//  Facemash
//
//  Created by Peter Shih on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Constants.h"

@implementation AboutViewController

@synthesize howToPlay = _howToPlay;
@synthesize profile = _profile;
@synthesize statistics = _statistics;
@synthesize leaderboards = _leaderboards;
@synthesize privacy = _privacy;
@synthesize aboutFacemash = _aboutFacemash;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.howToPlay = [@"Facemash is a fun, new, and exciting way to view Facebook © profile pictures on your mobile device.\n\nNormally Facemash will show profiles pictures from all around the world. In \"Friends Only Mode\" we will only show profile pictures of your friends and their friends.\n\nTo start mashing, choose a gender and two profile pictures will be shown. You can begin mashing by swiping the picture you like less off the screen.\n\nIn the rare case of an infinite loading wheel or an impossible decision (trust us, they will come up), just hit the refresh button in the top right corner to show two new profile pictures." retain];
    self.profile = [@"Your ranking, represented by military ranks, will be determined by how many faces you have mashed. The more you play, the faster you will fill the progress bar and thereby raise your rank.\n\nThe number of faces you have mashed will be separated into Global Mode and Friend Mode to help you keep track of your progress." retain];
    self.statistics = [@"Facemash uses the Elo Rating System (Google it!).\n\nWhen players mash profile pictures, a score is calculated for each picture. Over time you may be awarded with a special Facemash Title reflecting your accomplishments.\n\n\"Ranking within Facemash\" is your rank globally whereas \"Ranking among Friends\" shows how well you're doing among your friends and their friends." retain];
    self.leaderboards = [@"The leaderboards show you the Top 99 profile pictures.\n\nThe \"All Male\" and \"All Female\" tabs show the top 99 men and women globally.\n\nThe \"Male Friends\" and \"Female Friends\" tabs show the top 99 profile pictures when playing in Friend Mode.\n\nIf you want to see a larger image of a specific person, simply tap his or her cell for a larger view. Tap the image when you’re done to return to the leaderboards." retain];
    self.privacy = [@"We take privacy very seriously. We do not store any copies of profile pictures. We also do not store any information that is not publicly accessible on Facebook ©. We only use information you have explicitly allowed us to use. If there are any questions or concerns about your privacy, please feel free to contact us." retain];
    self.aboutFacemash = [@"Follow us on Twitter: @sevenminuteapps" retain];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Display logout button if this is current user's profile
  
  UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
  _navBarItem.rightBarButtonItem = doneButton;
  if ([_tableView respondsToSelector:@selector(backgroundView)]) {
    _tableView.backgroundView = nil;
  }
  _tableView.backgroundColor = [UIColor clearColor];
}

- (void)done {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGSize textSize;
  if(isDeviceIPad()) {
    textSize = CGSizeMake(400, INT_MAX);
  } else {
    textSize = CGSizeMake(440, INT_MAX);
  }

  switch (indexPath.section) {
    case 0: {
      CGSize howToPlaySize = [self.howToPlay sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return howToPlaySize.height + 20;
      break;
    }
    case 1: {
      CGSize profileSize = [self.profile sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return profileSize.height + 20;
      break;
    }
    case 2: {
      CGSize statisticsSize = [self.statistics sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return statisticsSize.height + 20;
      break;
    }
    case 3: {
      CGSize leaderboardsSize = [self.leaderboards sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return leaderboardsSize.height + 20;
      break;
    }
    case 4: {
      CGSize privacySize = [self.privacy sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return privacySize.height + 20;
      break;
    }
    case 5: {
      CGSize aboutFacemashSize = [self.aboutFacemash sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return aboutFacemashSize.height + 20;
      break;
    }
    default:
      return 44.0;
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 480, 44)] autorelease];
  headerView.backgroundColor = [UIColor clearColor];
  
  UILabel *headerLabel;
  if(isDeviceIPad()) {
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 400, 44)];
  } else {
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 440, 44)];
  }
  headerLabel.backgroundColor = [UIColor clearColor];
  
  switch (section) {
    case 0:
      headerLabel.text = @"How to Play Facemash";
      break;
    case 1:
      headerLabel.text = @"About Your Profile";
      break;
    case 2:
      headerLabel.text = @"About Your Statistics";
      break;
    case 3:
      headerLabel.text = @"About Your Statistics";
      break;
    case 4:
      headerLabel.text = @"About Your Privacy";
      break;
    case 5:
      headerLabel.text = @"About Facemash";
      break;
    default:
      break;
  }
  
  headerLabel.textColor = [UIColor whiteColor];
  headerLabel.font = [UIFont boldSystemFontOfSize:18.0];
  headerLabel.shadowColor = [UIColor darkGrayColor];
  headerLabel.shadowOffset = CGSizeMake(1, 1);
  [headerView addSubview:headerLabel];
  [headerLabel release];
  
  return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return;
  
  //  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//  return @"Here is the footer";
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  cell = [tableView dequeueReusableCellWithIdentifier:@"HowToCell"];
  if(cell == nil) { 
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HowToCell"] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 100;
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
  }
  switch (indexPath.section) {
    case 0:
      cell.textLabel.text = self.howToPlay;
      break;
    case 1:
      cell.textLabel.text = self.profile;
      break;
    case 2:
      cell.textLabel.text = self.statistics;
      break;
    case 3:
      cell.textLabel.text = self.leaderboards;
      break;
    case 4:
      cell.textLabel.text = self.privacy;
      break;
    case 5:
      cell.textLabel.text = self.aboutFacemash;
      break;
    default:
      break;
  }

  return cell;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  if(_howToPlay) [_howToPlay release];
  if(_profile) [_profile release];
  if(_statistics) [_statistics release];
  if(_leaderboards) [_leaderboards release];
  if(_privacy) [_privacy release];
  if(_aboutFacemash) [_aboutFacemash release];
  if(_navBarItem) [_navBarItem release];
  if(_tableView) [_tableView release];
  [super dealloc];
}


@end
