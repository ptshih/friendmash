//
//  ProfileViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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

@interface ProfileViewController (Private)
- (void)getProfileForCurrentUser;
@end

@implementation ProfileViewController

@synthesize launcherViewController = _launcherViewController;
@synthesize networkQueue = _networkQueue;
@synthesize profileDict = _profileDict;
@synthesize profileId = _profileId;
@synthesize delegate;

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
  
}

- (void)viewDidLoad {
  // Display logout button if this is current user's profile
  if(self.profileId == [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]) {
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
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/profile/%@", FACEMASH_BASE_URL, self.profileId];
  
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

- (void)requestFailed:(ASIHTTPRequest *)request
{
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
  
  UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 460, 44)];
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
  if(votes < 10) {
    return 0.0;
  } else if(votes < 50) {
    return 0.1;
  } else if(votes < 100) {
    return 0.2;
  } else if(votes < 250) {
    return 0.3;
  } else if(votes < 500) {
    return 0.4;
  } else if(votes < 750) {
    return 0.5;
  } else if(votes < 1000) {
    return 0.6;
  } else if(votes < 1500) {
    return 0.7;
  } else if(votes < 2000) {
    return 0.8;
  } else if(votes < 2500) {
    return 0.9;
  } else {
    return 1.0;
  }
}

- (UIImage *)getIconForVotes:(NSInteger)votes {
  if(votes < 10) {
    return [UIImage imageNamed:@"private.png"];
  } else if(votes < 50) {
    return [UIImage imageNamed:@"private_first_class.png"];
  } else if(votes < 100) {
    return [UIImage imageNamed:@"corporal.png"];
  } else if(votes < 250) {
    return [UIImage imageNamed:@"sergeant.png"];
  } else if(votes < 500) {
    return [UIImage imageNamed:@"staff_sergeant.png"];
  } else if(votes < 750) {
    return [UIImage imageNamed:@"sergeant_first_class.png"];
  } else if(votes < 1000) {
    return [UIImage imageNamed:@"master_sergeant.png"];
  } else if(votes < 1500) {
    return [UIImage imageNamed:@"first_sergeant.png"];
  } else if(votes < 2000) {
    return [UIImage imageNamed:@"sergeant_major.png"];
  } else if(votes < 2500) {
    return [UIImage imageNamed:@"command_sergeant_major.png"];
  } else {
    return [UIImage imageNamed:@"sergeant_major_army.png"];
  }
}

- (NSString *)getRankForVotes:(NSInteger)votes {
  // Calculate Rank Label based on number of votes
  if(votes < 10) {
    return @"Private";
  } else if(votes < 50) {
    return @"Private First Class";
  } else if(votes < 100) {
    return @"Corporal";
  } else if(votes < 250) {
    return @"Sergeant";
  } else if(votes < 500) {
    return @"Staff Sergeant";
  } else if(votes < 750) {
    return @"Sergeant First Class";
  } else if(votes < 1000) {
    return @"Master Sergeant";
  } else if(votes < 1500) {
    return @"First Sergeant";
  } else if(votes < 2000) {
    return @"Sergeant Major";
  } else if(votes < 2500) {
    return @"Command Sergeant Major";
  } else {
    return @"High Warlord";
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
      cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SettingsCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      switch (indexPath.row) {
        case 0:
          cell.textLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [NSString stringWithFormat:@"%@", [self getRankForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]]] : nil;
//          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [self getRankForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]] : nil;
          if([[self.profileDict objectForKey:@"votes"] notNil]) {
            UIImageView *rankView = [[UIImageView alloc] initWithImage:[self getIconForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]]];
            rankView.frame = CGRectMake(cell.contentView.frame.size.width - 40, 2, 36, 36);
            [cell.contentView addSubview:rankView];
          }
          break;
        case 1: {
          cell.textLabel.text = @"Facemash Progress";
          if([[self.profileDict objectForKey:@"votes"] notNil]) {
            UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            progressView.frame = CGRectMake(cell.contentView.frame.size.width - 225, 17, 215, 9);
            progressView.progress = [[self.profileDict objectForKey:@"votes"] notNil] ? [self getProgressForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]] : 0.0;
            [cell.contentView addSubview:progressView];
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
      cell = [tableView dequeueReusableCellWithIdentifier:@"BottomCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"BottomCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      switch (indexPath.row) {
        case 0:
          cell.textLabel.text = @"Facemash Title";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"score"] notNil] ? [self getTitleForScore:[[self.profileDict objectForKey:@"score"] integerValue]] : nil;
          break;
        case 1:
          cell.textLabel.text = @"Ranking Overall";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"rank"] notNil] ? [NSString stringWithFormat:@"%@ of %@",[[self.profileDict objectForKey:@"rank"] stringValue],[[self.profileDict objectForKey:@"total"] stringValue]] : nil;
          break;
        case 2:
          cell.textLabel.text = @"Ranking within Social Network";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"rank_network"] notNil] ? [NSString stringWithFormat:@"%@ of %@",[[self.profileDict objectForKey:@"rank_network"] stringValue],[[self.profileDict objectForKey:@"total"] stringValue]] : nil;
          break;
        case 3:
          cell.textLabel.text = @"Likes Received";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"wins"] notNil] ? [[self.profileDict objectForKey:@"wins"] stringValue] : nil;
          break;
        case 4:
          cell.textLabel.text = @"Dislikes Received";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"losses"] notNil] ? [[self.profileDict objectForKey:@"losses"] stringValue] : nil;
          break;
        case 5:
          cell.textLabel.text = @"Likes Received in a Row";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"win_streak"] notNil] ? [[self.profileDict objectForKey:@"win_streak"] stringValue] : nil;
          break;
        case 6:
          cell.textLabel.text = @"Dislikes Received in a Row";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"loss_streak"] notNil] ? [[self.profileDict objectForKey:@"loss_streak"] stringValue] : nil;
          break;
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
  [_networkQueue release];
  if(_profileDict) [_profileDict release];
  if(_profileId) [_profileId release];
  [super dealloc];
}


@end
