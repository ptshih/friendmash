//
//  RankingsViewController.m
//  Friendmash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "RankingsViewController.h"
#import "LauncherViewController.h"
#import "RankingsTableViewCell.h"
#import "LightboxViewController.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import "RemoteRequest.h"
#import "RemoteOperation.h"
#import "ASIHTTPRequest.h"

static UIImage *_placeholderImage;

@implementation RankingsViewController

@synthesize tableView = _tableView;
@synthesize tabBar = _tabBar;
@synthesize tabBarItemTop = _tabBarItemTop;
@synthesize tabBarItemMale = _tabBarItemMale;
@synthesize tabBarItemFemale = _tabBarItemFemale;
@synthesize loadingView = _loadingView;
@synthesize navItem = _navItem;
@synthesize refreshButton = _refreshButton;

@synthesize launcherViewController = _launcherViewController;
@synthesize rankingsArray = _rankingsArray;
@synthesize imageCache = _imageCache;
@synthesize rankingsRequest = _rankingsRequest;
@synthesize selectedMode = _selectedMode;
@synthesize gameMode = _gameMode;

+ (void)initialize {
  _placeholderImage = [[UIImage imageNamed:@"picture_loading.png"] retain];
}

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _rankingsArray = [[NSArray alloc] init];
    _imageCache = [[ImageCache alloc] init];
    self.imageCache.delegate = self;

    _selectedMode = 0;
    _gameMode = 0;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  // Tab bar gradient
//  CGRect frame = CGRectMake(0, 0, 480, 49);
//  UIView *v = [[UIView alloc] initWithFrame:frame];
//  UIImage *i = [UIImage imageNamed:@"tab_gradient.png"];
//  UIColor *c = [[UIColor alloc] initWithPatternImage:i];
//  v.backgroundColor = c;
//  [c release];
//  [_tabBar insertSubview:v atIndex:0];
//  [v release];
  
  // Call initial rankings
  // Read from userdefaults for sticky tab
  if([[NSUserDefaults standardUserDefaults] objectForKey:@"rankingsModeSticky"]) {
    self.selectedMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"rankingsModeSticky"] integerValue];
    switch (self.selectedMode) {
      case RankingsModeTop:
        self.tabBar.selectedItem = self.tabBarItemTop;
        break;
      case RankingsModeMale:
        self.tabBar.selectedItem = self.tabBarItemMale;
        break;
      case RankingsModeFemale:
        self.tabBar.selectedItem = self.tabBarItemFemale;
        break;
      default:
        break;
    }
  } else {
    self.selectedMode = RankingsModeTop;
    self.tabBar.selectedItem = self.tabBarItemTop;
  }
  
  [self refreshRankings];
}

#pragma mark  UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
  if([item isEqual:self.tabBarItemTop]) {
    [FlurryAPI logEvent:@"rankingsTabTop"];
    self.selectedMode = RankingsModeTop;    
  } else if([item isEqual:self.tabBarItemMale]) {
    [FlurryAPI logEvent:@"rankingsTabMale"];
    self.selectedMode = RankingsModeMale;
  } else if([item isEqual:self.tabBarItemFemale]) {
    [FlurryAPI logEvent:@"rankingsTabFemale"];
    self.selectedMode = RankingsModeFemale;
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:self.selectedMode forKey:@"rankingsModeSticky"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self refreshRankings];
}

- (IBAction)refreshRankings {
  self.refreshButton.enabled = NO;
  self.tabBarItemTop.enabled = NO;
  self.tabBarItemMale.enabled = NO;
  self.tabBarItemFemale.enabled = NO;
  self.tableView.userInteractionEnabled = NO;
  if(self.gameMode == 0) {
    self.tabBarItemMale.title = @"Top Male";
    self.tabBarItemFemale.title = @"Top Female";
  } else if (self.gameMode == 1) {
    self.tabBarItemMale.title = @"Top Male Friends";
    self.tabBarItemFemale.title = @"Top Female Friends";
  } else if (self.gameMode == 2) {
    self.tabBarItemMale.title = @"Top Males in Network";
    self.tabBarItemFemale.title = @"Top Females in Network";
  } else {
    self.tabBarItemMale.title = @"Top Male Classmates";
    self.tabBarItemFemale.title = @"Top Female Classmates";
  }


  
  if(self.selectedMode == RankingsModeTop) {
    [self getTopPlayers];
  } else {
    [self getTopRankings];
  } 
}

- (void)getTopPlayers {
  self.loadingView.hidden = NO;
  self.navItem.title = @"Top Players";
  [self.imageCache resetCache]; // reset the cache
  
  // Mode selection
  NSString *params = [NSString stringWithFormat:@"count=%d", FM_RANKINGS_COUNT];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/topplayers/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  self.rankingsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.rankingsRequest];
}

- (void)getTopRankings {
  self.loadingView.hidden = NO;
  [self.imageCache resetCache]; // reset the cache

  // Mode selection
  NSString *selectedGender = nil;
  if(self.selectedMode == RankingsModeMale) {
    if(self.gameMode == 0) {
      self.navItem.title = @"Top Male";
    } else if (self.gameMode == 1) {
      self.navItem.title = @"Top Male Friends";
    } else if (self.gameMode == 2) {
      self.navItem.title = @"Top Males in Network";
    } else {
      self.navItem.title = @"Top Male Classmates";
    }

    selectedGender = @"male";
  } else if(self.selectedMode == RankingsModeFemale) {
    if(self.gameMode == 0) {
      self.navItem.title = @"Top Female";
    } else if (self.gameMode == 1) {
      self.navItem.title = @"Top Female Friends";
    } else if (self.gameMode == 2) {
      self.navItem.title = @"Top Females in Network";
    } else {
      self.navItem.title = @"Top Female Classmates";
    }

    selectedGender = @"female";
  }

  NSString *params = [NSString stringWithFormat:@"gender=%@&mode=%d&count=%d", selectedGender, self.gameMode, FM_RANKINGS_COUNT];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/rankings/%@", FRIENDMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  self.rankingsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:self];
  [[RemoteOperation sharedInstance] addRequestToQueue:self.rankingsRequest];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // This is on the main thread
  // {"error":{"type":"OAuthException","message":"Error validating access token."}}
  NSInteger statusCode = [request responseStatusCode];
  if(statusCode > 200) {
    [FlurryAPI logEvent:@"errorRankingsRequestError"];
    UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
    [networkErrorAlert show];
    [networkErrorAlert autorelease];
  } else {  
    self.refreshButton.enabled = YES;
    self.tabBarItemTop.enabled = YES;
    self.tabBarItemMale.enabled = YES;
    self.tabBarItemFemale.enabled = YES;
    self.tableView.userInteractionEnabled = YES;
    self.rankingsArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
    [self.tableView reloadData];
  }
  self.loadingView.hidden = YES;
  DLog(@"rankings request finished successfully");
}

- (void)requestFailed:(ASIHTTPRequest *)request {
  [FlurryAPI logEvent:@"errorRankingsRequestFailed"];
  DLog(@"Request Failed with Error: %@", [request error]);
  UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
  [networkErrorAlert show];
  [networkErrorAlert autorelease];
  self.loadingView.hidden = YES;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      break;
    case 1:
      if(self.selectedMode == RankingsModeTop) {
        [self getTopPlayers];
      } else {
        [self getTopRankings];
      }
      break;
    default:
      break;
  }
}

- (IBAction)dismissRankings {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark ImageCacheDelegate
- (void)imageDidLoad:(NSIndexPath *)indexPath {
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 60.0;
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.rankingsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  RankingsTableViewCell *cell = (RankingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"RankingCell"];
	if(cell == nil) { 
		cell = [[[RankingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RankingCell"] autorelease];
		cell.backgroundColor = [UIColor clearColor];
		cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_cell_bg_landscape.png"]];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"table_cell_bg_selected.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:20]];
    
//		cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_cell_bg_landscape.png"]];
	}
  
  UIImage *profilePic = [self.imageCache getImageForIndexPath:indexPath];
  if(!profilePic) {
    if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
    {
      ASIHTTPRequest *pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:[[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"] andType:@"square" withDelegate:nil];
      [self.imageCache cacheImageWithRequest:pictureRequest forIndexPath:indexPath];
    }
    profilePic = _placeholderImage;
  }
  
  if(self.selectedMode == RankingsModeTop) {
    [RankingsTableViewCell fillCell:cell withDictionary:[self.rankingsArray objectAtIndex:indexPath.row] andImage:profilePic forTopPlayers:YES];
  } else {
    [RankingsTableViewCell fillCell:cell withDictionary:[self.rankingsArray objectAtIndex:indexPath.row] andImage:profilePic forTopPlayers:NO];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  [FlurryAPI logEvent:@"rankingsTapped" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"], @"facebookId", [NSNumber numberWithInteger:self.selectedMode], @"selectedMode", nil]];
   
  // Popup a lightbox view with full sized image
  LightboxViewController *lvc;
  if(isDeviceIPad()) {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPad" bundle:nil];
  } else {
    lvc = [[LightboxViewController alloc] initWithNibName:@"LightboxViewController_iPhone" bundle:nil];
  }
  lvc.facebookId = [[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"];
  [self presentModalViewController:lvc animated:YES];
  [lvc release];
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)
// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  if (!decelerate)
  {
    [self loadImagesForOnscreenRows];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  [self loadImagesForOnscreenRows];
}

- (void)loadImagesForOnscreenRows
{
  NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
  for (NSIndexPath *indexPath in visiblePaths)
  {
    if(![self.imageCache getImageForIndexPath:indexPath]) {
      ASIHTTPRequest *pictureRequest = [RemoteRequest getFacebookRequestForPictureWithFacebookId:[[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"] andType:@"square" withDelegate:nil];
      [self.imageCache cacheImageWithRequest:pictureRequest forIndexPath:indexPath];
    }
  }
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
  if(_rankingsRequest) {
    [_rankingsRequest clearDelegatesAndCancel];
    [_rankingsRequest release];
  }
  
  // IBOutlets
  RELEASE_SAFELY(_tableView);
  RELEASE_SAFELY(_tabBar);
  RELEASE_SAFELY(_tabBarItemTop);
  RELEASE_SAFELY(_tabBarItemMale);
  RELEASE_SAFELY(_tabBarItemFemale);
  RELEASE_SAFELY(_loadingView);
  RELEASE_SAFELY(_navItem);
  RELEASE_SAFELY(_refreshButton);
  
  // IVARS
  if(_imageCache) [_imageCache release];
  if(_rankingsArray) [_rankingsArray release];

  [super dealloc];
}


@end
