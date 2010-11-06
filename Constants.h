/*
 *  Constants.h
 *  Facemash
 *
 *  Created by Peter Shih on 10/8/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "FacemashAppDelegate.h"
#import "NSString+Util.h"

// IF enabled, we will use local client side friends list
//#define USE_OFFLINE_MODE
#define USE_ROUNDED_CORNERS

#define STAGING

#ifdef STAGING
  #define FACEMASH_BASE_URL @"http://localhost:3000"
#else
  #define FACEMASH_BASE_URL @"http://facemash.heroku.com"
#endif

#define FB_APP_ID @"151779758183785"
#define FB_APP_SECRET @"77bcf63d51d3062fed22da00243998ae"
#define FB_PERMISSIONS [NSArray arrayWithObjects:@"user_birthday",@"friends_birthday",@"user_relationships",@"friends_relationships",nil]

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