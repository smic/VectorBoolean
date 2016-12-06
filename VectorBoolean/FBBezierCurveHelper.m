//
//  FBBezierCurveHelper.m
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierCurveHelper.h"
#import "FBNormalizedLine.h"
#import "FBGeometry.h"

#pragma mark Helper functions

//////////////////////////////////////////////////////////////////////////////////
// Helper functions
//

CGFloat FBParameterOfPointOnLine(CGPoint lineStart, CGPoint lineEnd, CGPoint point)
{
    // Note: its asumed you have already checked that point is colinear with the line (lineStart, lineEnd)
    CGFloat lineLength = FBDistanceBetweenPoints(lineStart, lineEnd);
    CGFloat lengthFromStart = FBDistanceBetweenPoints(point, lineStart);
    CGFloat parameter = lengthFromStart / lineLength;
    
    // The only tricky thing here is the sign. Is the point _before_ lineStart, or after lineStart?
    CGFloat lengthFromEnd = FBDistanceBetweenPoints(point, lineEnd);
    if ( FBAreValuesClose(lineLength + lengthFromStart, lengthFromEnd) )
        parameter = -parameter;
    
    return parameter;
}

BOOL FBLinesIntersect(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End, CGPoint *outIntersect)
{
    FBNormalizedLine line1 = FBNormalizedLineMake(line1Start, line1End);
    FBNormalizedLine line2 = FBNormalizedLineMake(line2Start, line2End);
    *outIntersect = FBNormalizedLineIntersection(line1, line2);
    if ( isnan(outIntersect->x) || isnan(outIntersect->y) )
        return NO;
    outIntersect->y = -outIntersect->y;
    return YES;
}

// The three points are a counter-clockwise turn if the return value is greater than 0,
//  clockwise if less than 0, or colinear if 0.
CGFloat CounterClockwiseTurn(CGPoint point1, CGPoint point2, CGPoint point3)
{
    // We're calculating the signed area of the triangle formed by the three points. Well,
    //  almost the area of the triangle -- we'd need to divide by 2. But since we only
    //  care about the direction (i.e. the sign) dividing by 2 is an unnecessary step.
    // See http://mathworld.wolfram.com/TriangleArea.html for the signed area of a triangle.
    return (point2.x - point1.x) * (point3.y - point1.y) - (point2.y - point1.y) * (point3.x - point1.x);
}

// Calculate if and where the given line intersects the horizontal line at y.
BOOL LineIntersectsHorizontalLine(CGPoint startPoint, CGPoint endPoint, CGFloat y, CGPoint *intersectPoint)
{
    // Do a quick test to see if y even falls on the startPoint,endPoint line
    CGFloat minY = MIN(startPoint.y, endPoint.y);
    CGFloat maxY = MAX(startPoint.y, endPoint.y);
    if ( (y < minY && !FBAreValuesClose(y, minY)) || (y > maxY && !FBAreValuesClose(y, maxY)) )
        return NO;
    
    // There's an intersection here somewhere
    if ( startPoint.x == endPoint.x )
        *intersectPoint = CGPointMake(startPoint.x, y);
    else {
        CGFloat slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
        *intersectPoint = CGPointMake((y - startPoint.y) / slope + startPoint.x, y);
    }
    
    return YES;
}

CGPoint BezierWithPoints(NSUInteger degree, CGPoint *bezierPoints, CGFloat parameter, CGPoint *leftCurve, CGPoint *rightCurve)
{
    // Calculate a point on the bezier curve passed in, specifically the point at parameter.
    //  We're using De Casteljau's algorithm, which not only calculates the point at parameter
    //  in a numerically stable way, it also computes the two resulting bezier curves that
    //  would be formed if the original were split at the parameter specified.
    //
    // See: http://www.cs.mtu.edu/~shene/COURSES/cs3621/NOTES/spline/Bezier/de-casteljau.html
    //  for an explaination of De Casteljau's algorithm.
    
    // bezierPoints, leftCurve, rightCurve will have a length of degree + 1.
    // degree is the order of the bezier path, which will be cubic (3) most of the time.
    
    // With this algorithm we start out with the points in the bezier path.
    CGPoint points[6] = {}; // we assume we'll never get more than a cubic bezier
    for (NSUInteger i = 0; i <= degree; i++)
        points[i] = bezierPoints[i];
    
    // If the caller is asking for the resulting bezier curves, start filling those in
    if ( leftCurve != nil )
        leftCurve[0] = points[0];
    if ( rightCurve != nil )
        rightCurve[degree] = points[degree];
    
    for (NSUInteger k = 1; k <= degree; k++) {
        for (NSUInteger i = 0; i <= (degree - k); i++) {
            points[i].x = (1.0 - parameter) * points[i].x + parameter * points[i + 1].x;
            points[i].y = (1.0 - parameter) * points[i].y + parameter * points[i + 1].y;
        }
        
        if ( leftCurve != nil )
            leftCurve[k] = points[0];
        if ( rightCurve != nil )
            rightCurve[degree - k] = points[degree - k];
    }
    
    // The point in the curve at parameter ends up in points[0]
    return points[0];
}

void FBComputeCubicFirstDerivativeRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *outRoots, NSUInteger *outRootsCount)
{
    // See http://processingjs.nihongoresources.com/bezierinfo/#bounds for where the formulas come from
    CGFloat denominator = -a + 3.0 * b - 3.0 * c + d;
    if ( !FBAreValuesClose(denominator, 0.0) ) {
        CGFloat numeratorLeft = -a + 2.0 * b - c;
        CGFloat numeratorRight = -sqrt(-a * (c - d) + b * b - b * (c + d) + c * c);
        CGFloat t1 = (numeratorLeft + numeratorRight) / denominator;
        CGFloat t2 = (numeratorLeft - numeratorRight) / denominator;
        outRoots[0] = t1;
        outRoots[1] = t2;
        *outRootsCount = 2;
        return;
    }
    
    // If denominator == 0, fall back to
    CGFloat t = (a - b) / (2.0 * (a - 2.0 * b + c));
    outRoots[0] = t;
    *outRootsCount = 1;
}



NSInteger FBSign(CGFloat value)
{
    return value < 0.0 ? -1.0 : 1.0;
}

NSUInteger FBCountBezierCrossings(CGPoint *bezierPoints, NSUInteger degree)
{
    NSUInteger count = 0;
    NSInteger sign = FBSign(bezierPoints[0].y);
    NSInteger previousSign = sign;
    for (NSInteger i = 1; i <= degree; i++) {
        sign = FBSign(bezierPoints[i].y);
        if ( sign != previousSign )
            count++;
        previousSign = sign;
    }
    return count;
}

static const NSUInteger FBFindBezierRootsMaximumDepth = 64;

BOOL FBIsControlPolygonFlatEnough(CGPoint *bezierPoints, NSUInteger degree, CGPoint *intersectionPoint)
{
    CGFloat FBFindBezierRootsErrorThreshold = ldexpf(1, -(int)(FBFindBezierRootsMaximumDepth - 1));
    
    FBNormalizedLine line = FBNormalizedLineMake(bezierPoints[0], bezierPoints[degree]);
    
    // Find the bounds around the line
    CGFloat belowDistance = 0;
    CGFloat aboveDistance = 0;
    for (NSUInteger i = 1; i < degree; i++) {
        CGFloat distance = FBNormalizedLineDistanceFromPoint(line, bezierPoints[i]);
        if ( distance > aboveDistance )
            aboveDistance = distance;
        if ( distance < belowDistance )
            belowDistance = distance;
    }
    
    FBNormalizedLine zeroLine = FBNormalizedLineMakeWithCoefficients(0, 1, 0);
    FBNormalizedLine aboveLine = FBNormalizedLineOffset(line, -aboveDistance);
    CGPoint intersect1 = FBNormalizedLineIntersection(zeroLine, aboveLine);
    
    FBNormalizedLine belowLine = FBNormalizedLineOffset(line, -belowDistance);
    CGPoint intersect2 = FBNormalizedLineIntersection(zeroLine, belowLine);
    
    CGFloat error = MAX(intersect1.x, intersect2.x) - MIN(intersect1.x, intersect2.x);
    if ( error < FBFindBezierRootsErrorThreshold ) {
        *intersectionPoint = FBNormalizedLineIntersection(zeroLine, line);
        return YES;
    }
    
    return NO;
}

void FBFindBezierRootsWithDepth(CGPoint *bezierPoints, NSUInteger degree, NSUInteger depth, void (^block)(CGFloat root))
{
    NSUInteger crossingCount = FBCountBezierCrossings(bezierPoints, degree);
    if ( crossingCount == 0 )
        return;
    else if ( crossingCount == 1 ) {
        if ( depth >= FBFindBezierRootsMaximumDepth ) {
            CGFloat root = (bezierPoints[0].x + bezierPoints[degree].x) / 2.0;
            block(root);
            return;
        }
        CGPoint intersectionPoint = CGPointZero;
        if ( FBIsControlPolygonFlatEnough(bezierPoints, degree, &intersectionPoint) ) {
            block(intersectionPoint.x);
            return;
        }
    }
    
    // Subdivide and try again
    CGPoint leftCurve[6] = {}; // assume 5th degree
    CGPoint rightCurve[6] = {};
    BezierWithPoints(degree, bezierPoints, 0.5, leftCurve, rightCurve);
    FBFindBezierRootsWithDepth(leftCurve, degree, depth + 1, block);
    FBFindBezierRootsWithDepth(rightCurve, degree, depth + 1, block);
}

void FBFindBezierRoots(CGPoint *bezierPoints, NSUInteger degree, void (^block)(CGFloat root))
{
    FBFindBezierRootsWithDepth(bezierPoints, degree, 0, block);
}
