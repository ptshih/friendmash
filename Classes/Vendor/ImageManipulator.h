//
//  ImageManipulator.h
//  Facemash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageManipulator : NSObject {
}
+(UIImage *)makeRoundCornerImage:(UIImage*)img :(int) cornerWidth :(int) cornerHeight;
@end