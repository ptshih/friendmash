//
//  RankingsViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RankingsViewController.h"
#import "LauncherViewController.h"
#import "RankingsTableViewCell.h"
#import "LightboxViewController.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import "RemoteRequest.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

static UIImage *_placeholderImage;

@implementation RankingsViewController

@synthesize launcherViewController = _launcherViewController;
@synthesize rankingsArray = _rankingsArray;
@synthesize imageCache = _imageCache;
@synthesize networkQueue = _networkQueue;
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
    
    _networkQueue = [[ASINetworkQueue queue] retain];
    
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setShouldCancelAllRequestsOnFailure:NO];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
    
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
        _tabBar.selectedItem = _tabBarItemTop;
        break;
      case RankingsModeMale:
        _tabBar.selectedItem = _tabBarItemMale;
        break;
      case RankingsModeFemale:
        _tabBar.selectedItem = _tabBarItemFemale;
        break;
      default:
        break;
    }
  } else {
    self.selectedMode = RankingsModeTop;
    _tabBar.selectedItem = _tabBarItemTop;
  }
  
  if(self.selectedMode == RankingsModeTop) {
    [self getTopPlayers];
  } else {
    [self getTopRankings];
  }
}

#pragma mark  UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
  if([item isEqual:_tabBarItemTop]) {
    self.selectedMode = RankingsModeTop;    
  } else if([item isEqual:_tabBarItemMale]) {
    self.selectedMode = RankingsModeMale;
  } else if([item isEqual:_tabBarItemFemale]) {
    self.selectedMode = RankingsModeFemale;
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:self.selectedMode forKey:@"rankingsModeSticky"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if(self.selectedMode == RankingsModeTop) {
    [self getTopPlayers];
  } else {
    [self getTopRankings];
  }
}

- (void)getTopPlayers {
  _loadingView.hidden = NO;
  [self.imageCache resetCache]; // reset the cache
  
  // Mode selection
  NSString *params = [NSString stringWithFormat:@"count=%d", FM_RANKINGS_COUNT];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/topplayers/%@", FACEMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  ASIHTTPRequest *rankingsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:rankingsRequest];
  [self.networkQueue go];
}

- (void)getTopRankings {
  _loadingView.hidden = NO;
  [self.imageCache resetCache]; // reset the cache
  
  // Mode selection
  NSString *selectedGender;
  if(self.selectedMode == RankingsModeMale) {
    selectedGender = @"male";
  } else if(self.selectedMode == RankingsModeFemale) {
    selectedGender = @"female";
  }

  NSString *params = [NSString stringWithFormat:@"gender=%@&mode=%d&count=%d", selectedGender, self.gameMode, FM_RANKINGS_COUNT];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/rankings/%@", FACEMASH_BASE_URL, APP_DELEGATE.currentUserId];
  
  ASIHTTPRequest *rankingsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:rankingsRequest];
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
  } else {  
    self.rankingsArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
    [_tableView reloadData];
  }
  _loadingView.hidden = YES;
  DLog(@"rankings request finished successfully");
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  DLog(@"Request Failed with Error: %@", [request error]);
  UIAlertView *networkErrorAlert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:FM_NETWORK_ERROR delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
  [networkErrorAlert show];
  [networkErrorAlert autorelease];
  _loadingView.hidden = YES;
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
  [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
    if (_tableView.dragging == NO && _tableView.decelerating == NO)
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
  NSArray *visiblePaths = [_tableView indexPathsForVisibleRows];
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
  self.networkQueue.delegate = nil;
  [self.networkQueue cancelAllOperations];
  if(_networkQueue) [_networkQueue release];
  if(_imageCache) [_imageCache release];
  if(_rankingsArray) [_rankingsArray release];
  if(_tableView) [_tableView release];
  if(_tabBar) [_tabBar release];
  if(_tabBarItemTop) [_tabBarItemTop release];
  if(_tabBarItemMale) [_tabBarItemMale release];
  if(_tabBarItemFemale) [_tabBarItemFemale release];
  if(_loadingView) [_loadingView release];
  [super dealloc];
}


@end
