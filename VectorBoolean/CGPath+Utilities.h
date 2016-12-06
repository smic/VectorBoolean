//
//  CGPath+Utilities.h
//  VectorBrush
//
//  Created by Andrew Finnell on 5/28/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef void(^CGPathEnumerationHandler)(const CGPathElement *element);

extern void CGPathEnumerateElementsUsingBlock(CGPathRef path, CGPathEnumerationHandler handler);

extern CGPathRef CGPathCreateWithCircleAtPoint(CGPoint point);
extern CGPathRef CGPathCreateWithRectAtPoint(CGPoint point);
extern CGPathRef CGPathCreateWithSmallCircleAtPoint(CGPoint point);
extern CGPathRef CGPathCreateWithSmallRectAtPoint(CGPoint point);
extern CGPathRef CGPathCreateWithTriangleAtPoint(CGPoint point, CGPoint direction);
