//
//  AboutViewController.m
//  Friendmash
//
//  Created by Peter Shih on 11/13/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "AboutViewController.h"
#import "Constants.h"

@implementation AboutViewController

@synthesize navBarItem = _navBarItem;
@synthesize tableView = _tableView;

@synthesize howToPlay = _howToPlay;
@synthesize profile = _profile;
@synthesize leaderboards = _leaderboards;
@synthesize aboutFriendmash = _aboutFriendmash;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.howToPlay = [@"Friendmash is a fun, new, and exciting way to view and compare Facebook profile pictures on the go!\n\nNormally, Friendmash will show profile pictures from all around the world. In \"Show Friends\" mode we will only show you pictures of your friends. In \"Show Friends of Friends\" mode we will only show you pictures of your social network (friends and friends of friends).\n\nTo start mashing, simply choose a gender and two profile pictures will be shown.\n\nTap the picture you like better or long press (tap and hold) to zoom in on any picture. If you can't decide which picture is better, just hit the refresh button in the top right corner to load two new pictures." retain];
    
    self.profile = [@"Your ranking is determined by how many faces you have mashed. The more you play, the faster you will fill the progress bar and thereby raise your rank.\n\nPeriodically we will be adding more fun statistics. Check your profile page often to see your progress!" retain];
    
    self.leaderboards = [@"The \"Top Players\" tab will show the top 99 mashers whereas the \"Top Men\" and \"Top Women\" tabs will show the top 99 male and female profile pictures as rated by you and other players.\n\nIf you want to see a larger image of a particular person, simply tap his/her row for a larger view. Tap the screen when you’re done to return to the leaderboards." retain];
    
    self.aboutFriendmash = [@"Follow us on Twitter: @sevenminuteapps\nFacebook is a registered trademark of Facebook, Inc." retain];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Display logout button if this is current user's profile
  
  UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
  self.navBarItem.rightBarButtonItem = doneButton;
  if ([self.tableView respondsToSelector:@selector(backgroundView)]) {
    self.tableView.backgroundView = nil;
  }
  self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)done {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGSize textSize;
  if (isDeviceIPad()) {
    textSize = CGSizeMake(460, INT_MAX);
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
      CGSize leaderboardsSize = [self.leaderboards sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return leaderboardsSize.height + 20;
      break;
    }
    case 3: {
      CGSize aboutFriendmashSize = [self.aboutFriendmash sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return aboutFriendmashSize.height + 20;
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
      headerLabel.text = @"How to Play Friendmash";
      break;
    case 1:
      headerLabel.text = @"About Your Profile";
      break;
    case 2:
      headerLabel.text = @"The Leaderboards";
      break;
    case 3:
      headerLabel.text = @"About Friendmash";
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
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//  return @"Here is the footer";
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 4;
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
      cell.textLabel.text = self.leaderboards;
      break;
    case 3:
      cell.textLabel.text = self.aboutFriendmash;
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
  // IBOutlets
  RELEASE_SAFELY(_navBarItem);
  RELEASE_SAFELY(_tableView);
  
  // IVARS
  RELEASE_SAFELY(_howToPlay);
  RELEASE_SAFELY(_profile);
  RELEASE_SAFELY(_leaderboards);
  RELEASE_SAFELY(_aboutFriendmash);
  
  [super dealloc];
}


@end
