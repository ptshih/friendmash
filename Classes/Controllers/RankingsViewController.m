    //
//  SettingsViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RankingsViewController.h"
#import "LauncherViewController.h"
#import "Constants.h"
#import "CJSONDeserializer.h"
#import <QuartzCore/QuartzCore.h>

@implementation RankingsViewController

@synthesize launcherViewController = _launcherViewController;
@synthesize rankingsArray = _rankingsArray;
@synthesize imageCache = _imageCache;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _rankingsArray = [[NSArray alloc] init];
    _imageCache = [[ImageCache alloc] init];
    self.imageCache.delegate = self;
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
  NSString *urlString = [NSString stringWithFormat:@"%@/mash/rankings?%@", FACEMASH_BASE_URL, params];
  ASIHTTPRequest *rankingsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
  [rankingsRequest setDelegate:self];
  [rankingsRequest setRequestMethod:@"GET"];
  [rankingsRequest addRequestHeader:@"Content-Type" value:@"application/json"];
  [rankingsRequest addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [rankingsRequest startAsynchronous];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
  // This is on the main thread
  self.rankingsArray = [[CJSONDeserializer deserializer] deserializeAsArray:[request responseData] error:nil];
  [_tableView reloadData];
  DLog(@"rankings request finished successfully");
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
  // NSError *error = [request error];
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
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RankingCell"];
	if(cell == nil) { 
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RankingCell"] autorelease];
		cell.backgroundColor = [UIColor clearColor];
		cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_cell_bg_landscape.png"]];
//		cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_cell_bg_landscape.png"]];
	}
  
  UIImage *profilePic = [self.imageCache getImageForIndexPath:indexPath];
  if(profilePic) {
    cell.imageView.image = profilePic;
  } else {
    if (_tableView.dragging == NO && _tableView.decelerating == NO)
    {
      NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
      NSString *params = [NSString stringWithFormat:@"access_token=%@", token];
      NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?%@", [[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"], params];
      [self.imageCache cacheImageWithURL:[NSURL URLWithString:urlString] forIndexPath:indexPath];
    }
    cell.imageView.image = [UIImage imageNamed:@"picture_loading.png"];
  }
  cell.imageView.layer.cornerRadius = 5.0;
  cell.imageView.layer.masksToBounds = YES;
  cell.textLabel.text = [[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
  NSString *token = [APP_DELEGATE.fbAccessToken stringWithPercentEscape];
  NSString *params = [NSString stringWithFormat:@"access_token=%@", token];
  NSArray *visiblePaths = [_tableView indexPathsForVisibleRows];
  for (NSIndexPath *indexPath in visiblePaths)
  {
    if(![self.imageCache getImageForIndexPath:indexPath]) {
      NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?%@", [[self.rankingsArray objectAtIndex:indexPath.row] objectForKey:@"facebook_id"], params];
      [self.imageCache cacheImageWithURL:[NSURL URLWithString:urlString] forIndexPath:indexPath];
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
  [_imageCache release];
  [_rankingsArray release];
  [super dealloc];
}


@end
