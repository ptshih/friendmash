    //
//  SettingsViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RankingsViewController.h"
#import "LauncherViewController.h"
#import "RankingsTableViewCell.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import "RemoteRequest.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"


@implementation RankingsViewController

@synthesize launcherViewController = _launcherViewController;
@synthesize rankingsArray = _rankingsArray;
@synthesize imageCache = _imageCache;
@synthesize networkQueue = _networkQueue;

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
  }
  return self;
}

- (void)viewDidLoad {
  // Call initial rankings
  [self getTopRankingsForGender:@"male" andMode:0];
}

- (void)viewWillAppear:(BOOL)animated {
  
}

- (void)getTopRankingsForGender:(NSString *)gender andMode:(NSInteger)mode {
  NSString *params = [NSString stringWithFormat:@"gender=%@&mode=%d", gender, mode];
  NSString *baseURLString = [NSString stringWithFormat:@"%@/mash/rankings/%@", FACEMASH_BASE_URL, [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"]];
  
  ASIHTTPRequest *rankingsRequest = [RemoteRequest getRequestWithBaseURLString:baseURLString andParams:params withDelegate:nil];
  [self.networkQueue addOperation:rankingsRequest];
  [self.networkQueue go];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // This is on the main thread
  // {"error":{"type":"OAuthException","message":"Error validating access token."}}
  self.rankingsArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
  [_tableView reloadData];
  DLog(@"rankings request finished successfully");
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

- (IBAction)selectMode:(UISegmentedControl *)segmentedControl {
  DLog(@"selected section: %d", segmentedControl.selectedSegmentIndex);
  [self.imageCache resetCache]; // reset the cache when switching segments
  switch (segmentedControl.selectedSegmentIndex) {
    case 0:
      [self getTopRankingsForGender:@"male" andMode:0];
      break;
    case 1:
      [self getTopRankingsForGender:@"female" andMode:0];
      break;
    case 2:
      [self getTopRankingsForGender:@"male" andMode:1];
      break;
    case 3:
      [self getTopRankingsForGender:@"female" andMode:1];
      break;
    default:
      [self getTopRankingsForGender:@"male" andMode:0];
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
    profilePic = [UIImage imageNamed:@"picture_loading.png"];
  }
  
  [RankingsTableViewCell fillCell:cell withDictionary:[self.rankingsArray objectAtIndex:indexPath.row] andImage:profilePic];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
//  WebViewController *wvc = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
//  [self presentModalViewController:wvc animated:YES];
//  [wvc setWebViewTitle:[[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"full_name"]];
//  [wvc loadURL:[NSString stringWithFormat:@"http://touch.facebook.com/#/profile.php?id=%@&access_token=%@", [[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"], APP_DELEGATE.fbAccessToken]];
//  [wvc release];
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
  if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) return YES;
  else return NO;
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
  [_imageCache release];
  [_rankingsArray release];
  [super dealloc];
}


@end
