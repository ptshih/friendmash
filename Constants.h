/*
 *  Constants.h
 *  Facemash
 *
 *  Created by Peter Shih on 10/8/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "FacemashAppDelegate.h"
#import "FlurryAPI.h"

/*
 tagline:
 facemash: settings standards one swipe at a time
 
 overlay getting started in facemash view controller
 
 Stuff TODO for v2:
 
 Profile picture slider (paging) for rankings on the bottom of the screem. Then when the user stops on a picture the top half of the screen will show profile info.
 
 */

#define USE_ROUNDED_CORNERS

#ifdef __APPLE__
  #include "TargetConditionals.h"
#endif

#if TARGET_IPHONE_SIMULATOR
  #define STAGING
#endif

#ifdef STAGING
  #define FACEMASH_BASE_URL @"http://localhost:3000"
  #define FACEMASH_TERMS_URL @"http://localhost:3000/terms"
  #define FACEMASH_PRIVACY_URL @"http://localhost:3000/privacy"
#else
  #define FACEMASH_BASE_URL @"http://facemash.heroku.com"
  #define FACEMASH_TERMS_URL @"http://facemash.heroku.com/terms"
  #define FACEMASH_PRIVACY_URL @"http://facemash.heroku.com/privacy"
#endif

#define FB_GRAPH_FRIENDS @"https://graph.facebook.com/me/friends"
#define FB_GRAPH_ME @"https://graph.facebook.com/me"

#define FB_APP_ID @"147806651932979"
#define FB_APP_SECRET @"587e59801ee014c9fdea54ad17e626c6"
#define FB_PERMISSIONS [NSArray arrayWithObjects:@"offline_access",@"user_photos",@"friends_photos",@"user_education_history",@"friends_education_history",@"user_work_history",@"friends_work_history",nil]
#define FB_PARAMS @"id,first_name,last_name,name,gender,education,work,locale"
#define FB_AUTHORIZE_URL @"https://www.facebook.com/dialog/oauth"
//#define FB_AUTHORIZE_URL @"https://graph.facebook.com/oauth/authorize"

// #define FB_EXPIRE_TOKEN // if defined, will send a request to FB to expire a user's token

// Unused, FB doesn't seem to return these
// interested_in
// meeting_for

#define WEBVIEW_LEFT @"left.png"
#define WEBVIEW_RIGHT @"right.png"

#define FM_RANKINGS_COUNT 99

// ERROR STRINGS
#define FM_NETWORK_ERROR @"Facemash has encountered a network error. Please check your network connection and try again."

//#define OAUTH_TOKEN @"151779758183785|2.mlbpS5_RD5Ao_hTpWQtBVg__.3600.1289080800-548430564|es6q1fc8hb7pSL2UpwFegiF1F8c"

#define RGBCOLOR(R,G,B) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1.0]
#define RGBACOLOR(R,G,B,A) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]

// App Delegate Macro
#define APP_DELEGATE ((FacemashAppDelegate *)[[UIApplication sharedApplication] delegate])

// Logging Macros
#ifdef DEBUG
#	define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define DLog(...)
#endif

//#define VERBOSE_DEBUG
#ifdef VERBOSE_DEBUG
#define VLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define VLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

// Detect Device Type
static BOOL isDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES; 
  }
#endif
  return NO;
}