//
//  FBBezierCurveHelper.h
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat FBParameterOfPointOnLine(CGPoint lineStart, CGPoint lineEnd, CGPoint point);
extern BOOL FBLinesIntersect(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End, CGPoint *outIntersect);
extern CGFloat CounterClockwiseTurn(CGPoint point1, CGPoint point2, CGPoint point3);
extern BOOL LineIntersectsHorizontalLine(CGPoint startPoint, CGPoint endPoint, CGFloat y, CGPoint *intersectPoint);
extern CGPoint BezierWithPoints(NSUInteger degree, CGPoint *bezierPoints, CGFloat parameter, CGPoint *leftCurve, CGPoint *rightCurve);

extern void FBComputeCubicFirstDerivativeRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *outRoots, NSUInteger *outRootsCount);

extern NSInteger FBSign(CGFloat value);
extern NSUInteger FBCountBezierCrossings(CGPoint *bezierPoints, NSUInteger degree);
extern BOOL FBIsControlPolygonFlatEnough(CGPoint *bezierPoints, NSUInteger degree, CGPoint *intersectionPoint);

extern void FBFindBezierRootsWithDepth(CGPoint *bezierPoints, NSUInteger degree, NSUInteger depth, void (^block)(CGFloat root));
extern void FBFindBezierRoots(CGPoint *bezierPoints, NSUInteger degree, void (^block)(CGFloat root));
