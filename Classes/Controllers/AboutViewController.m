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
@synthesize aboutFacemash = _aboutFacemash;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.howToPlay = [@"It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap! It's a trap!" retain];
    self.aboutFacemash = [@"Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! Hammer Time! " retain];
  }
  return self;
}

- (void)viewDidLoad {
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
  CGSize textSize = CGSizeMake(440, INT_MAX);
  switch (indexPath.section) {
    case 0: {
      CGSize howToPlaySize = [self.howToPlay sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
      return howToPlaySize.height + 20;
      break;
    }
    case 1: {
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
  if(isDeviceIPad() || __IPHONE_OS_VERSION_MAX_ALLOWED <= 30200) {
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
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: // how to play
      return 1;
      break;
    case 1: // about
      return 1;
      break;
    default:
      return 0;
      break;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  switch (indexPath.section) {
    case 0:
      cell = [tableView dequeueReusableCellWithIdentifier:@"HowToCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HowToCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 100;
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
      }
      cell.textLabel.text = self.howToPlay;
      break;
    case 1:
      cell = [tableView dequeueReusableCellWithIdentifier:@"AboutCell"];
      if(cell == nil) { 
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AboutCell"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 100;
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
      }
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
  if(_aboutFacemash) [_aboutFacemash release];
  if(_navBarItem) [_navBarItem release];
  if(_tableView) [_tableView release];
  [super dealloc];
}


@end
