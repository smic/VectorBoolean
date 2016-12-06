//
//  CGPath+Utilities.m
//  VectorBrush
//
//  Created by Andrew Finnell on 5/28/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "CGPath+Utilities.h"
#import "FBGeometry.h"

static const CGFloat FBDebugPointSize = 10.0;
static const CGFloat FBDebugSmallPointSize = 3.0;

void CGPathEnumerationCallback(void *info, const CGPathElement *element)
{
	CGPathEnumerationHandler handler = (__bridge CGPathEnumerationHandler)(info);
	if (handler) {
		handler(element);
	}
}

void CGPathEnumerateElementsUsingBlock(CGPathRef path, CGPathEnumerationHandler handler)
{
	void CGPathEnumerationCallback(void *info, const CGPathElement *element);
	CGPathApply(path, (__bridge void * _Nullable)(handler), CGPathEnumerationCallback);
}

CGPathRef CGPathCreateWithCircleAtPoint(CGPoint point)
{
	CGRect rect = CGRectMake(point.x - FBDebugPointSize * 0.5, point.y - FBDebugPointSize * 0.5, FBDebugPointSize, FBDebugPointSize);
	
	return CGPathCreateWithEllipseInRect(rect, NULL);
}

CGPathRef CGPathCreateWithRectAtPoint(CGPoint point)
{
	CGRect rect = CGRectMake(point.x - FBDebugPointSize * 0.5 * 1.3, point.y - FBDebugPointSize * 0.5 * 1.3, FBDebugPointSize * 1.3, FBDebugPointSize * 1.3);
	
	return CGPathCreateWithRect(rect, NULL);
}

CGPathRef CGPathCreateWithSmallCircleAtPoint(CGPoint point)
{
	CGRect rect = CGRectMake(point.x - FBDebugSmallPointSize * 0.5, point.y - FBDebugSmallPointSize * 0.5, FBDebugSmallPointSize, FBDebugSmallPointSize);
	
	return CGPathCreateWithEllipseInRect(rect, NULL);
}

CGPathRef CGPathCreateWithSmallRectAtPoint(CGPoint point)
{
	CGRect rect = CGRectMake(point.x - FBDebugSmallPointSize * 0.5, point.y - FBDebugSmallPointSize * 0.5, FBDebugSmallPointSize, FBDebugSmallPointSize);
	
	return CGPathCreateWithRect(rect, NULL);
}

CGPathRef CGPathCreateWithTriangleAtPoint(CGPoint point, CGPoint direction)
{
	CGPoint endPoint = FBAddPoint(point, FBScalePoint(direction, FBDebugPointSize * 1.5));
	CGPoint normal1 = FBLineNormal(point, endPoint);
	CGPoint normal2 = CGPointMake(-normal1.x, -normal1.y);
	CGPoint basePoint1 = FBAddPoint(point, FBScalePoint(normal1, FBDebugPointSize * 0.5));
	CGPoint basePoint2 = FBAddPoint(point, FBScalePoint(normal2, FBDebugPointSize * 0.5));
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, basePoint1.x, basePoint1.y);
	CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y);
	CGPathAddLineToPoint(path, NULL, basePoint2.x, basePoint2.y);
	CGPathAddLineToPoint(path, NULL, basePoint1.x, basePoint1.y);
	CGPathCloseSubpath(path);
	return path;
}
