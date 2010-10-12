/*
 *  Constants.h
 *  Facemash
 *
 *  Created by Peter Shih on 10/8/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

// IF enabled, we will use local client side friends list
#define USE_OFFLINE_MODE

#define RGBCOLOR(R,G,B) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1.0]
#define RGBACOLOR(R,G,B,A) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]

static BOOL isDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES; 
  }
#endif
  return NO;
}