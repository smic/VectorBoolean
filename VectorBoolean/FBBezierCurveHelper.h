//
//  FBBezierCurveHelper.h
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat FBParameterOfPointOnLine(NSPoint lineStart, NSPoint lineEnd, NSPoint point);
extern BOOL FBLinesIntersect(NSPoint line1Start, NSPoint line1End, NSPoint line2Start, NSPoint line2End, NSPoint *outIntersect);
extern CGFloat CounterClockwiseTurn(NSPoint point1, NSPoint point2, NSPoint point3);
extern BOOL LineIntersectsHorizontalLine(NSPoint startPoint, NSPoint endPoint, CGFloat y, NSPoint *intersectPoint);
extern NSPoint BezierWithPoints(NSUInteger degree, NSPoint *bezierPoints, CGFloat parameter, NSPoint *leftCurve, NSPoint *rightCurve);

extern void FBComputeCubicFirstDerivativeRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *outRoots, NSUInteger *outRootsCount);

extern NSInteger FBSign(CGFloat value);
extern NSUInteger FBCountBezierCrossings(NSPoint *bezierPoints, NSUInteger degree);
extern BOOL FBIsControlPolygonFlatEnough(NSPoint *bezierPoints, NSUInteger degree, NSPoint *intersectionPoint);

extern void FBFindBezierRootsWithDepth(NSPoint *bezierPoints, NSUInteger degree, NSUInteger depth, void (^block)(CGFloat root));
extern void FBFindBezierRoots(NSPoint *bezierPoints, NSUInteger degree, void (^block)(CGFloat root));