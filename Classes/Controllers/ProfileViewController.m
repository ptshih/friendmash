//
//  ProfileViewController.m
//  Friendmash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "ProfileViewController.h"
#import "LauncherViewController.h"
#import "RemoteRequest.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import "NSString+ConvenienceMethods.h"
#import "NSObject+ConvenienceMethods.h"

static UIImage *_likeImage;
//static UIImage *_dislikeImage;

@interface ProfileViewController (Private)
- (void)getProfileForCurrentUser;
@end

@implementation ProfileViewController

@synthesize launcherViewController = _launcherViewController;
@synthesize networkQueue = _networkQueue;
@synthesize profileDict = _profileDict;
@synthesize profileId = _profileId;
@synthesize delegate;

+ (void)initialize {
  _likeImage = [[UIImage imageNamed:@"likes.png"] retain];
//  _dislikeImage = [[UIImage imageNamed:@"unlike.png"] retain];
}

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
      _networkQueue = [[ASINetworkQueue queue] retain];
      
      [[self networkQueue] setDelegate:self];
      [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
      [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
      [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
      [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Display logout button if this is current user's profile
  if(self.profileId == APP_DELEGATE.currentUserId) {
    UIBarButtonItem *logoutButton = [[[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout)] autorelease];
    _navBarItem.leftBarButtonItem = logoutButton;
  }
  
  UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
  _navBarItem.rightBarButtonItem = doneButton;  
  if ([_tableView respondsToSelector:@selector(backgroundView)]) {
    _tableView.backgroundView = nil;
  }
  _tableView.backgroundColor = [UIColor clearColor];
  [self getProfileForCurrentUser];
}

- (void)logout {
  [delegate shouldPerformLogout];
  [self dismissModalViewControllerAnimated:YES];
}

- (void)done {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)getProfileForCurrentUser {
//  NSString *params = [NSString stringWithFormat:@"gender=%@&mode=%d&count=%d", gender, mode, FM_RANKINGS_COUNT];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/profile/%@", FRIENDMASH_BASE_URL, self.profileId];
  
  ASIHTTPRequest *profileRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:nil withDelegate:nil];
  [self.networkQueue addOperation:profileRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // This is on the main thread
  // {"error":{"type":"OAuthException","message":"Error validating access token."}}
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    [FlurryAPI logEvent:@"errorProfileRequestError"];
    UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
    [networkErrorAlert show];
    [networkErrorAlert autorelease];
    return;
  }
  
  self.profileDict = [[[CJSONDeserializer deserializer] deserializeAsDictionary:[request responseData] error:nil] objectForKey:@"user"];
  
  [_tableView reloadData];
  DLog(@"rankings request finished successfully");
  DLog(@"profile dict: %@", self.profileDict);
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  [FlurryAPI logEvent:@"errorProfileRequestFailed"];
  DLog(@"Request Failed with Error: %@", [request error]);
  UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
  [networkErrorAlert show];
  [networkErrorAlert autorelease];
}

- (void)queueFinished:(ASINetworkQueue *)queue {
  DLog(@"Queue finished");
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      break;
    case 1:
      [self getProfileForCurrentUser];
      break;
    default:
      break;
  }
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44.0;
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
      headerLabel.text = [[self.profileDict objectForKey:@"full_name"] notNil] ? [NSString stringWithFormat:@"%@'s Achievements",[self.profileDict objectForKey:@"full_name"]] : @"My Achievements";
      break;
    case 1:
      headerLabel.text = [[self.profileDict objectForKey:@"full_name"] notNil] ? [NSString stringWithFormat:@"%@'s Statistics",[self.profileDict objectForKey:@"full_name"]] : @"My Statistics";
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

- (float)getProgressForVotes:(NSInteger)votes {
  int k = 100;
  if(votes < k) {
    return (float)votes / k;
  } else if(votes < 2*k) {
    return (float)(votes - k) / k;
  } else if(votes < 4*k) {
    return (float)(votes - 2*k) / (2*k);
  } else if(votes < 6*k) {
    return (float)(votes - 4*k) / (4*k);
  } else if(votes < 8*k) {
    return (float)(votes - 6*k) / (6*k);
  } else if(votes < 10*k) {
    return (float)(votes - 8*k) / (8*k);
  } else if(votes < 14*k) {
    return (float)(votes - 10*k) / (10*k);
  } else if(votes < 18*k) {
    return (float)(votes - 14*k) / (14*k);
  } else if(votes < 22*k) {
    return (float)(votes - 18*k) / (18*k);
  } else if(votes < 26*k) {
    return (float)(votes - 22*k) / (22*k);
  } else if(votes < 30*k) {
    return (float)(votes - 26*k) / (26*k);
  } else if(votes < 40*k) {
    return (float)(votes - 30*k) / (30*k);
  } else if(votes < 50*k) {
    return (float)(votes - 40*k) / (40*k);
  } else if(votes < 60*k) {
    return (float)(votes - 50*k) / (50*k);
  } else if(votes < 70*k) {
    return (float)(votes - 60*k) / (60*k);
  } else if(votes < 80*k) {
    return (float)(votes - 70*k) / (70*k);
  } else if(votes < 100*k) {
    return (float)(votes - 80*k) / (80*k);
  } else if(votes < 120*k) {
    return (float)(votes - 100*k) / (100*k);
  } else if(votes < 140*k) {
    return (float)(votes - 120*k) / (120*k);
  } else if(votes < 160*k) {
    return (float)(votes - 140*k) / (140*k);
  } else if(votes < 180*k) {
    return (float)(votes - 160*k) / (160*k);
  } else {
    return 1.0;
  }
}

- (UIImage *)getIconForVotes:(NSInteger)votes {
  int k = 100;
  if(votes < k) {
    return [UIImage imageNamed:@"recruit.png"];
  } else if(votes < 2*k) {
    return [UIImage imageNamed:@"apprentice.png"];
  } else if(votes < 4*k) {
    return [UIImage imageNamed:@"private.png"];
  } else if(votes < 6*k) {
    return [UIImage imageNamed:@"corporal.png"];
  } else if(votes < 8*k) {
    return [UIImage imageNamed:@"sergeant.png"];
  } else if(votes < 10*k) {
    return [UIImage imageNamed:@"first_sergeant.png"];
  } else if(votes < 14*k) {
    return [UIImage imageNamed:@"lieutenant.png"];
  } else if(votes < 18*k) {
    return [UIImage imageNamed:@"first_lieutenant.png"];
  } else if(votes < 22*k) {
    return [UIImage imageNamed:@"captain.png"];
  } else if(votes < 26*k) {
    return [UIImage imageNamed:@"staff_captain.png"];
  } else if(votes < 30*k) {
    return [UIImage imageNamed:@"major.png"];
  } else if(votes < 40*k) {
    return [UIImage imageNamed:@"major_payne.png"];
  } else if(votes < 50*k) {
    return [UIImage imageNamed:@"commander.png"];
  } else if(votes < 60*k) {
    return [UIImage imageNamed:@"strike_commander.png"];
  } else if(votes < 70*k) {
    return [UIImage imageNamed:@"colonel.png"];
  } else if(votes < 80*k) {
    return [UIImage imageNamed:@"force_colonel.png"];
  } else if(votes < 100*k) {
    return [UIImage imageNamed:@"brigadier.png"];
  } else if(votes < 120*k) {
    return [UIImage imageNamed:@"brigadier_general.png"];
  } else if(votes < 140*k) {
    return [UIImage imageNamed:@"general.png"];
  } else if(votes < 160*k) {
    return [UIImage imageNamed:@"three_star_general.png"];
  } else if(votes < 180*k) {
    return [UIImage imageNamed:@"four_star_general.png"];
  } else {
    return [UIImage imageNamed:@"five_star_general.png"];
  }
}

- (NSString *)getRankForVotes:(NSInteger)votes {
  int k = 100;
  // Calculate Rank Label based on number of votes
  if(votes < k) {
    return @"Recruit";
  } else if(votes < 2*k) {
    return @"Apprentice";
  } else if(votes < 4*k) {
    return @"Private";
  } else if(votes < 6*k) {
    return @"Corporal";
  } else if(votes < 8*k) {
    return @"Sergeant";
  } else if(votes < 10*k) {
    return @"First Sergeant";
  } else if(votes < 14*k) {
    return @"Lieutenant";
  } else if(votes < 18*k) {
    return @"First Lieutenant";
  } else if(votes < 22*k) {
    return @"Captain";
  } else if(votes < 26*k) {
    return @"Captain America";
  } else if(votes < 30*k) {
    return @"Major";
  } else if(votes < 40*k) {
    return @"Major Payne";
  } else if(votes < 50*k) {
    return @"Commander";
  } else if(votes < 60*k) {
    return @"Strike Commander";
  } else if(votes < 70*k) {
    return @"Colonel";
  } else if(votes < 80*k) {
    return @"Colonel Sanders";
  } else if(votes < 100*k) {
    return @"Brigadier";
  } else if(votes < 120*k) {
    return @"Brigadier General";
  } else if(votes < 140*k) {
    return @"General";
  } else if(votes < 160*k) {
    return @"3-Star General";
  } else if(votes < 180*k) {
    return @"4-Star General";
  } else {
    return @"5-Star General";
  }
}

- (NSString *)getTitleForScore:(NSInteger)score {
  if(score < 1600) {
    return @"Challenger";
  } else if(score < 1800) {
    return @"Rival";
  } else if(score < 2000) {
    return @"Duelist";
  } else if(score < 2200) {
    return @"Gladiator";
  } else {
    return @"Champion";
  }
}

#pragma mark UITableViewDataSource
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//  return @"Here is the footer";
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: // user profile
      return 4;
      break;
    case 1: // stats
      return 7;
      break;
    default:
      return 0;
      break;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;

  // Cell Customization
  switch (indexPath.section) {
    case 0:
      cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProfileCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      switch (indexPath.row) {
        case 0:
          cell.textLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [NSString stringWithFormat:@"%@", [self getRankForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]]] : @"Loading...";
          cell.detailTextLabel.text = nil;
          if([[self.profileDict objectForKey:@"votes"] notNil]) {
            UIImageView *rankView = [[UIImageView alloc] initWithImage:[self getIconForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]]];
            rankView.frame = CGRectMake(cell.contentView.frame.size.width - 39, 0, 29, 44);
            [cell.contentView addSubview:rankView];
            [rankView release];
          }
          break;
        case 1: {
          cell.textLabel.text = @"Mashes to Next Rank";
          cell.detailTextLabel.text = nil;
          if([[self.profileDict objectForKey:@"votes"] notNil]) {
            UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            progressView.frame = CGRectMake(cell.contentView.frame.size.width - 225, 17, 215, 9);
            progressView.progress = [self getProgressForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]];
            [cell.contentView addSubview:progressView];
            [progressView release];
          }
          break;
        }
        case 2:
          cell.textLabel.text = @"Number of Faces Mashed";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [[self.profileDict objectForKey:@"votes"] stringValue] : nil;
          break;
        case 3:
          cell.textLabel.text = @"Number of Friends Mashed";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"votes_network"] notNil] ? [[self.profileDict objectForKey:@"votes_network"] stringValue] : nil;
          break;
        default:
          break;
      }
      
      break;
    case 1:
      cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileStatsCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProfileStatsCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      switch (indexPath.row) {
        case 0:
          cell.textLabel.text = @"Awarded Title";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"score"] notNil] ? [self getTitleForScore:[[self.profileDict objectForKey:@"score"] integerValue]] : nil;
          break;
        case 1:
          cell.textLabel.text = @"Ranking within Friendmash";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"rank"] notNil] ? [NSString stringWithFormat:@"%@ of %@",[[self.profileDict objectForKey:@"rank"] stringValue],[[self.profileDict objectForKey:@"total"] stringValue]] : nil;
          break;
        case 2:
          cell.textLabel.text = @"Ranking among Friends";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"rank_network"] notNil] ? [NSString stringWithFormat:@"%@ of %@",[[self.profileDict objectForKey:@"rank_network"] stringValue],[[self.profileDict objectForKey:@"total_network"] stringValue]] : nil;
          break;
        case 3:
          cell.imageView.image = _likeImage;
          cell.textLabel.text = @"Likes Received from Other Players";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"wins"] notNil] ? [[self.profileDict objectForKey:@"wins"] stringValue] : nil;
          break;
        case 4:
          cell.imageView.image = _likeImage;
          cell.textLabel.text = @"Likes Received from Friends";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"wins_network"] notNil] ? [[self.profileDict objectForKey:@"wins_network"] stringValue] : nil;
          break;
        case 5:
          cell.imageView.image = _likeImage;
          cell.textLabel.text = @"Longest Like Streak";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"win_streak_max"] notNil] ? [[self.profileDict objectForKey:@"win_streak_max"] stringValue] : nil;
          break;
        case 6:
          cell.imageView.image = _likeImage;
          cell.textLabel.text = @"Longest Like Streak from Friends";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"win_streak_max_network"] notNil] ? [[self.profileDict objectForKey:@"win_streak_max_network"] stringValue] : nil;
          break;
//        case 4:
//          cell.imageView.image = _dislikeImage;
//          cell.textLabel.text = @"Dislikes";
//          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"losses"] notNil] ? [[self.profileDict objectForKey:@"losses"] stringValue] : nil;
//          break;
//        case 6:
//          cell.imageView.image = _dislikeImage;
//          cell.textLabel.text = @"Dislikes in a row";
//          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"loss_streak"] notNil] ? [[self.profileDict objectForKey:@"loss_streak"] stringValue] : nil;
//          break;
        default:
          break;
      }
      break;
    default:
      break;
  }

  return cell;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];

  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  if(_profileDict) [_profileDict release];
  if(_profileId) [_profileId release];
  if(_navBarItem) [_navBarItem release];
  if(_tableView) [_tableView release];
  [super dealloc];
}


@end
