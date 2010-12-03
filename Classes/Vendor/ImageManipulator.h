//
//  ImageManipulator.h
//  Friendmash
//
//  Created by Peter Shih on 10/11/10.
//  Copyright 2010 Seven Minute Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageManipulator : NSObject {
  
}

+ (UIImage *)roundCornerImageWithImage:(UIImage*)img withCornerWidth:(NSUInteger)cornerWidth withCornerHeight:(NSUInteger)cornerHeight;

+ (UIImage *)imageWithBorderFromImage:(UIImage *)source;

@end