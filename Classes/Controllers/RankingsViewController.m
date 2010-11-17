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
@synthesize selectedGender = _selectedGender;

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
    
    self.selectedGender = [@"male" retain];
    _selectedMode = 0;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Call initial rankings
  // Read from userdefaults for sticky tab
  if([[NSUserDefaults standardUserDefaults] objectForKey:@"rankingsStickyGender"]) {
    self.selectedGender = [[NSUserDefaults standardUserDefaults] objectForKey:@"rankingsStickyGender"];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"rankingsStickyGender"]) {
      _selectedMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"rankingsStickyMode"];
      if(_selectedMode == 0) {
        if([self.selectedGender isEqualToString:@"male"]) {
          [_segmentedControl setSelectedSegmentIndex:0];
        } else {
          [_segmentedControl setSelectedSegmentIndex:1];
        }
      } else {
        if([self.selectedGender isEqualToString:@"male"]) {
          [_segmentedControl setSelectedSegmentIndex:2];
        } else {
          [_segmentedControl setSelectedSegmentIndex:3];
        }
      }
    }
  }
  
  [self getTopRankings];
}

- (IBAction)getTopRankings {
  _loadingView.hidden = NO;
  [self.imageCache resetCache]; // reset the cache
  
  NSString *params = [NSString stringWithFormat:@"gender=%@&mode=%d&count=%d", self.selectedGender, _selectedMode, FM_RANKINGS_COUNT];
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
      [self getTopRankings];
      break;
    default:
      break;
  }
}

- (IBAction)selectMode:(UISegmentedControl *)segmentedControl {
  DLog(@"selected section: %d", segmentedControl.selectedSegmentIndex);
  [self.imageCache resetCache]; // reset the cache when switching segments
  switch (segmentedControl.selectedSegmentIndex) {
    case 0:
      self.selectedGender = @"male";
      _selectedMode = 0;
      break;
    case 1:
      self.selectedGender = @"female";
      _selectedMode = 0;
      break;
    case 2:
      self.selectedGender = @"male";
      _selectedMode = 1;
      break;
    case 3:
      self.selectedGender = @"female";
      _selectedMode = 1;
      break;
    default:
      self.selectedGender = @"male";
      _selectedMode = 0;
      break;
  }
  [[NSUserDefaults standardUserDefaults] setObject:self.selectedGender forKey:@"rankingsStickyGender"];
  [[NSUserDefaults standardUserDefaults] setInteger:_selectedMode forKey:@"rankingsStickyMode"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self getTopRankings];
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
  
  [RankingsTableViewCell fillCell:cell withDictionary:[self.rankingsArray objectAtIndex:indexPath.row] andImage:profilePic];
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
  if(_selectedGender) [_selectedGender release];
  if(_tableView) [_tableView release];
  if(_segmentedControl) [_segmentedControl release];
  if(_loadingView) [_loadingView release];
  [super dealloc];
}


@end
