//
//  NSString+ConvenienceMethods.m
//  Wikinvest
//
//  Created by Peter Shih on 8/12/10.
//  Copyright 2010 Wikinvest. All rights reserved.
//

#import "NSString+ConvenienceMethods.h"


@implementation NSString (ConvenienceMethods)

- (BOOL)notNull {
	return ![self isEqualToString:@"(null)"];
}

@end
