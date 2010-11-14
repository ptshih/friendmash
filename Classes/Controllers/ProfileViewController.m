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
  _tableView.backgroundView = nil;
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
    UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
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
  UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
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
      headerLabel.text = @"My Achievements";
      break;
    case 1:
      headerLabel.text = @"Facemash Statistics";
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

- (NSString *)getRankForVotes:(NSInteger)votes {
  // Calculate Rank Label based on number of votes
  if(votes < 10) {
    return @"Scout";
  } else if(votes < 50) {
    return @"Grunt";
  } else if(votes < 100) {
    return @"Sergeant";
  } else if(votes < 150) {
    return @"Knight";
  } else if(votes < 250) {
    return @"Legionnaire";
  } else if(votes < 350) {
    return @"Centurion";
  } else if(votes < 500) {
    return @"Champion";
  } else if(votes < 650) {
    return @"Commander";
  } else if(votes < 800) {
    return @"General";
  } else if(votes < 1000) {
    return @"Warlord";
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
    return @"Vanquisher";
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
      return 3;
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
          cell.textLabel.text = @"Facemash Rank";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [self getRankForVotes:[[self.profileDict objectForKey:@"votes"] integerValue]] : nil;
          break;
        case 1:
          cell.textLabel.text = @"Number of Mashes";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"votes"] notNil] ? [[self.profileDict objectForKey:@"votes"] stringValue] : nil;
          break;
        case 2:
          cell.textLabel.text = @"Number of Mashes within Social Network";
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
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"rank"] notNil] ? [NSString stringWithFormat:@"%@ of %@",[[self.profileDict objectForKey:@"rank"] stringValue],[[self.profileDict objectForKey:@"total"] stringValue]] : nil;
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
          cell.textLabel.text = @"Like Streak";
          cell.detailTextLabel.text = [[self.profileDict objectForKey:@"win_streak"] notNil] ? [[self.profileDict objectForKey:@"win_streak"] stringValue] : nil;
          break;
        case 6:
          cell.textLabel.text = @"Dislike Streak";
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
