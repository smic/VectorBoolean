//
//  CGPath+Boolean.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

extern CGPathRef CGPathUnion(CGPathRef path1, CGPathRef path2);
extern CGPathRef CGPathIntersect(CGPathRef path1, CGPathRef path2);
extern CGPathRef CGPathDifference(CGPathRef path1, CGPathRef path2);
extern CGPathRef CGPathXOR(CGPathRef path1, CGPathRef path2);
