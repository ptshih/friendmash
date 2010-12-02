//
//  NSString+Util.m
//  Friendmash
//
//  Created by Peter Shih on 11/6/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import "NSString+Util.h"


@implementation NSString (Util)

- (NSString *)stringWithPercentEscape {            
  return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[self mutableCopy] autorelease], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"),kCFStringEncodingUTF8) autorelease];
}

@end
