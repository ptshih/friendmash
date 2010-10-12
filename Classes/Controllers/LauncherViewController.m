    //
//  LauncherViewController.m
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "FacemashViewController.h"
#import "Constants.h"
#import "OBFacemashClient.h"
#import "CJSONDeserializer.h"
#import "OBCoreDataStack.h"

@interface LauncherViewController (Private)
/**
 Initiate a bind with Facebook for OAuth token
 */
- (void)bindWithFacebook;

/**
 This method checks to see if an OAuth token exists for FB.
 If a token exists, we are already bound and will load, position, and display the left/right faceViews.
 Also send a request to get an NSDictionary of the current user and store it in userDefaults.
 If a token does not exist, remove left/right views from superview and perform FB authorization.
 */
- (void)checkAuthAndGetCurrentUser;

/**
 This method creates and pushes the FacemashViewController and sets it's iVar to the designated gender
 */
- (void)launchFacemashWithGender:(NSString *)gender;

/**
 Shows the gender selection splash screen
 */
- (void)displayLauncher;

@end

@implementation LauncherViewController

@synthesize currentUserRequest = _currentUserRequest;
@synthesize friendsRequest = _friendsRequest;
@synthesize postUserRequest = _postUserRequest;
@synthesize postFriendsRequest = _postFriendsRequest;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
//  self.title = NSLocalizedString(@"facemash", @"facemash");
  self.view.backgroundColor = RGBCOLOR(59,89,152);
  
  // Check token and authorize
  [self bindWithFacebook];
}

- (void)viewWillAppear:(BOOL)animated {
  self.navigationController.navigationBar.hidden = YES;
  [self displayLauncher];
}

- (void)displayLauncher {
  if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    _launcherView.hidden = NO;
    [_activityIndicator stopAnimating];
  } else {
    _launcherView.hidden = YES;
    [_activityIndicator startAnimating];
  }
}

- (IBAction)male {
  [self launchFacemashWithGender:@"male"];
}
- (IBAction)female {
  [self launchFacemashWithGender:@"female"];
}

- (void)launchFacemashWithGender:(NSString *)gender {
  FacemashViewController *fvc;
  if(isDeviceIPad()) {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPad" bundle:nil];
  } else {
    fvc = [[FacemashViewController alloc] initWithNibName:@"FacemashViewController_iPhone" bundle:nil];
  }
  fvc.gender = gender;
  [self.navigationController pushViewController:fvc animated:YES];
  [fvc release];
}

#pragma mark OAuth / FBConnect
- (void)bindWithFacebook {
  [OBFacebookOAuthService bindWithDelegate:self andView:self.view]; 
}

- (void)checkAuthAndGetCurrentUser {
  if([OBFacebookOAuthService isBound]) {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"hasSentFriendsList"]) {
//      [self performSelectorOnMainThread:@selector(launchFacemash) withObject:nil waitUntilDone:YES];
      [self displayLauncher];
    } else {
      self.currentUserRequest = [OBFacebookOAuthService getCurrentUserWithDelegate:self];
      self.friendsRequest = [OBFacebookOAuthService getFriendsWithDelegate:self];
    }
  }
}

- (void)fbLogin {
  
}

- (void)fbLogout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to logout of Facebook?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      break;
    case 1:
      [OBFacebookOAuthService unbindWithDelegate:self];
      break;
    default:
      break;
  }
}

#pragma mark OBOAuthServiceDelegate
- (void)oauthService:(Class)service didReceiveAccessToken:(OBOAuthToken *)accessToken {
  NSLog(@"Got access token:%@ with key: %@ and secret: %@", accessToken, accessToken.key, accessToken.secret);
  
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  //store the token
  [OBOAuthToken persistTokens];
  [self checkAuthAndGetCurrentUser];
}

- (void)dismissCredentialsView {
  if (self.modalViewController) {
    [self dismissModalViewControllerAnimated:YES];
  }
}

- (void)oauthService:(Class)service didFailToAuthenticateWithError:(NSError *)error {
  if ([[error domain] isEqualToString:OBOAuthServiceErrorDomain]) {
    if ([error code] == OBOAuthServiceErrorInvalidCredentials) {
      [self performSelectorOnMainThread:@selector(showBadCredentialsAlert) withObject:nil waitUntilDone:YES];
    }
  }
}

- (void)showBadCredentialsAlert {
  NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ Error", @"service error title format"), @"Facebook"];
  NSString *message = NSLocalizedString(@"Error authenticating, please check your credentials and try again.", @"error bad credentials");
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"ok button title") otherButtonTitles:nil] autorelease];
  [alert show];
}

- (void)oauthServiceDidUnbind:(Class)service {
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasSentFriendsList"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self bindWithFacebook];
}

#pragma mark OBClientOperationDelegate
- (void)obClientOperation:(OBClientOperation *)operation willSendRequest:(NSURLRequest *)request {
}

- (void)obClientOperation:(OBClientOperation *)operation failedToSendRequest:(NSURLRequest *)request withError:(NSError *)error {
}

- (void)obClientOperation:(OBClientOperation *)operation didProcessResponse:(OBClientResponse *)response {
  if ([operation.request isEqual:self.currentUserRequest]) {
    //this should be an object response
    if ([response isKindOfClass:[OBClientObjectResponse class]]) {
      OBClientObjectResponse *obj = (OBClientObjectResponse *)response;
      
      //get the entity id for the current user.
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      OBFacebookUser *user = (OBFacebookUser *)[context objectWithID:obj.entityID];
      
#ifndef USE_OFFLINE_MODE
      self.postUserRequest = [OBFacemashClient postUser:user withDelegate:self];
#endif
      
      [[NSUserDefaults standardUserDefaults] setObject:user.facebookId forKey:@"currentUserId"];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [context release];
    } else {
      NSLog(@"Got the wrong response back for the current user request, should be an object response but was: %@", response);
    }
  } else if ([operation.request isEqual:self.friendsRequest]) {
    //this operation should be a collection response
    if ([response isKindOfClass:[OBClientCollectionResponse class]]) {
      OBClientCollectionResponse *collection = (OBClientCollectionResponse *)response;
      
      //send the friends list up to the server
      NSManagedObjectContext *context = [OBCoreDataStack newManagedObjectContext];
      
      NSMutableArray *friends = [NSMutableArray array];
      for (NSManagedObjectID *objectID in collection.list) {
        NSManagedObject *obj = [context objectWithID:objectID];
        if (obj) {
          [friends addObject:obj];
        }
      }
      
      //send the friends
#ifndef USE_OFFLINE_MODE
      NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserId"];
      if(facebookId) self.postFriendsRequest = [OBFacemashClient postFriendsForFacebookId:facebookId withArray:friends withDelegate:self];
#endif
      [context release];
    }
  }
}

- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request {
  if(request == self.postFriendsRequest) {
    [self displayLauncher];
  } else if(request == self.postUserRequest) {
  } else if(request == self.friendsRequest) {
    NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:[operation responseData] error:nil];
    NSArray *responseArray = [responseDict objectForKey:@"data"];
    [[NSUserDefaults standardUserDefaults] setObject:responseArray forKey:@"friendsArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef USE_OFFLINE_MODE
    [self performSelectorOnMainThread:@selector(displayLauncher) withObject:nil waitUntilDone:YES];
#endif
  }
}
  
- (void)obClientOperation:(OBClientOperation *)operation didSendRequest:(NSURLRequest *)request whichFailedWithError:(NSError *)error {
  NSLog(@"Error sending request: %@ with error: %@",request, error);
  if(request == self.postFriendsRequest) {
    // resend request
  } else if(request == self.postUserRequest) {
    // resend request
  }
}

#pragma mark Memory Management
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
  if(_currentUserRequest) [_currentUserRequest release];
  if(_friendsRequest) [_friendsRequest release];
  if(_postUserRequest) [_postUserRequest release];
  if(_postFriendsRequest) [_postFriendsRequest release];
  [super dealloc];
}


@end
