//
//  FacemashViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FacemashViewController.h"
#import "Constants.h"

@implementation FacemashViewController

@synthesize leftView = _leftView;
@synthesize rightView = _rightView;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Custom initialization
    _leftView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
    _rightView = [[[NSBundle mainBundle] loadNibNamed:@"FaceView" owner:self options:nil] objectAtIndex:0];
  }
  return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NSLocalizedString(@"facemash", @"facemash");
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Login to Facebook" style:UIBarButtonItemStyleBordered target:self action:@selector(fbLogin)];
  
  // Face View
  self.leftView.frame = CGRectMake(40, 111, self.leftView.frame.size.width, self.leftView.frame.size.height);
  self.rightView.frame = CGRectMake(532, 111, self.rightView.frame.size.width, self.rightView.frame.size.height);
  [self.view addSubview:self.leftView];
  [self.view addSubview:self.rightView];
  
}

- (void)fbLogin {
 
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [_leftView release];
  [_rightView release];
  [super dealloc];
}

@end
