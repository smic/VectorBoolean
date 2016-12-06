//
//  Geometry.m
//  VectorBrush
//
//  Created by Andrew Finnell on 5/28/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBGeometry.h"

static const CGFloat FBPointClosenessThreshold = 1e-10;
static const CGFloat FBTangentClosenessThreshold = 1e-12;
static const CGFloat FBBoundsClosenessThreshold = 1e-9;


CGFloat FBDistanceBetweenPoints(CGPoint point1, CGPoint point2)
{
    CGFloat xDelta = point2.x - point1.x;
    CGFloat yDelta = point2.y - point1.y;
    return sqrt(xDelta * xDelta + yDelta * yDelta);
}

CGFloat FBDistancePointToLine(CGPoint point, CGPoint lineStartPoint, CGPoint lineEndPoint)
{
    CGFloat lineLength = FBDistanceBetweenPoints(lineStartPoint, lineEndPoint);
    if ( lineLength == 0 )
        return 0;
    CGFloat u = ((point.x - lineStartPoint.x) * (lineEndPoint.x - lineStartPoint.x) + (point.y - lineStartPoint.y) * (lineEndPoint.y - lineStartPoint.y)) / (lineLength * lineLength);
    CGPoint intersectionPoint = CGPointMake(lineStartPoint.x + u * (lineEndPoint.x - lineStartPoint.x), lineStartPoint.y + u * (lineEndPoint.y - lineStartPoint.y));
    return FBDistanceBetweenPoints(point, intersectionPoint);
}

CGPoint FBAddPoint(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

CGPoint FBUnitScalePoint(CGPoint point, CGFloat scale)
{
    CGPoint result = point;
    CGFloat length = FBPointLength(point);
    if ( length != 0.0 ) {
        result.x *= scale/length;
        result.y *= scale/length;
    }
    return result;
}

CGPoint FBScalePoint(CGPoint point, CGFloat scale)
{
    return CGPointMake(point.x * scale, point.y * scale);
}

CGFloat FBDotMultiplyPoint(CGPoint point1, CGPoint point2)
{
    return point1.x * point2.x + point1.y * point2.y;
}

CGPoint FBSubtractPoint(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point1.x - point2.x, point1.y - point2.y);
}

CGFloat FBPointLength(CGPoint point)
{
    return sqrt((point.x * point.x) + (point.y * point.y));
}

CGFloat FBPointSquaredLength(CGPoint point)
{
    return (point.x * point.x) + (point.y * point.y);
}

CGPoint FBNormalizePoint(CGPoint point)
{
    CGPoint result = point;
    CGFloat length = FBPointLength(point);
    if ( length != 0.0 ) {
        result.x /= length;
        result.y /= length;
    }
    return result;
}

CGPoint FBNegatePoint(CGPoint point)
{
    return CGPointMake(-point.x, -point.y);
}

CGPoint FBRoundPoint(CGPoint point)
{
    CGPoint result = { round(point.x), round(point.y) };
    return result;
}

CGPoint FBLineNormal(CGPoint lineStart, CGPoint lineEnd)
{
    return FBNormalizePoint(CGPointMake(-(lineEnd.y - lineStart.y), lineEnd.x - lineStart.x));
}

CGPoint FBLineMidpoint(CGPoint lineStart, CGPoint lineEnd)
{
    CGFloat distance = FBDistanceBetweenPoints(lineStart, lineEnd);
    CGPoint tangent = FBNormalizePoint(FBSubtractPoint(lineEnd, lineStart));
    return FBAddPoint(lineStart, FBUnitScalePoint(tangent, distance / 2.0));
}

CGPoint FBRectGetTopLeft(CGRect rect)
{
    return CGPointMake(NSMinX(rect), NSMinY(rect));
}

CGPoint FBRectGetTopRight(CGRect rect)
{
    return CGPointMake(NSMaxX(rect), NSMinY(rect));
}

CGPoint FBRectGetBottomLeft(CGRect rect)
{
    return CGPointMake(NSMinX(rect), NSMaxY(rect));
}

CGPoint FBRectGetBottomRight(CGRect rect)
{
    return CGPointMake(NSMaxX(rect), NSMaxY(rect));
}

void FBExpandBoundsByPoint(CGPoint *topLeft, CGPoint *bottomRight, CGPoint point)
{
    if ( point.x < topLeft->x )
        topLeft->x = point.x;
    if ( point.x > bottomRight->x )
        bottomRight->x = point.x;
    if ( point.y < topLeft->y )
        topLeft->y = point.y;
    if ( point.y > bottomRight->y )
        bottomRight->y = point.y;
}

CGRect FBUnionRect(CGRect rect1, CGRect rect2)
{
    CGPoint topLeft = FBRectGetTopLeft(rect1);
    CGPoint bottomRight = FBRectGetBottomRight(rect1);
    FBExpandBoundsByPoint(&topLeft, &bottomRight, FBRectGetTopLeft(rect2));
    FBExpandBoundsByPoint(&topLeft, &bottomRight, FBRectGetTopRight(rect2));
    FBExpandBoundsByPoint(&topLeft, &bottomRight, FBRectGetBottomRight(rect2));
    FBExpandBoundsByPoint(&topLeft, &bottomRight, FBRectGetBottomLeft(rect2));    
    return CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
}

BOOL FBArePointsClose(CGPoint point1, CGPoint point2)
{
    return FBArePointsCloseWithOptions(point1, point2, FBPointClosenessThreshold);
}

BOOL FBArePointsCloseWithOptions(CGPoint point1, CGPoint point2, CGFloat threshold)
{
    return FBAreValuesCloseWithOptions(point1.x, point2.x, threshold) && FBAreValuesCloseWithOptions(point1.y, point2.y, threshold);
}

BOOL FBAreValuesClose(CGFloat value1, CGFloat value2)
{
    return FBAreValuesCloseWithOptions(value1, value2, FBPointClosenessThreshold);
}

BOOL FBAreValuesCloseWithOptions(CGFloat value1, CGFloat value2, CGFloat threshold)
{
    CGFloat delta = value1 - value2;    
    return (delta <= threshold) && (delta >= -threshold);
}

//////////////////////////////////////////////////////////////////////////
// Helper methods for angles
//
static const CGFloat FB2PI = 2.0 * M_PI;

// Normalize the angle between 0 and 2pi
CGFloat NormalizeAngle(CGFloat value)
{
    while ( value < 0.0 )
        value += FB2PI;
    while ( value >= FB2PI )
        value -= FB2PI;
    return value;
}

// Compute the polar angle from the cartesian point
CGFloat PolarAngle(CGPoint point)
{
    CGFloat value = 0.0;
    if ( point.x > 0.0 )
        value = atan(point.y / point.x);
    else if ( point.x < 0.0 ) {
        if ( point.y >= 0.0 )
            value = atan(point.y / point.x) + M_PI;
        else
            value = atan(point.y / point.x) - M_PI;
    } else {
        if ( point.y > 0.0 )
            value =  M_PI_2;
        else if ( point.y < 0.0 )
            value =  -M_PI_2;
        else
            value = 0.0;
    }
    return NormalizeAngle(value);
}


FBAngleRange FBAngleRangeMake(CGFloat minimum, CGFloat maximum)
{
    FBAngleRange range = { minimum, maximum };
    return range;
}

static BOOL FBIsValueGreaterThanWithOptions(CGFloat value, CGFloat minimum, CGFloat threshold)
{
    if ( FBAreValuesCloseWithOptions(value, minimum, threshold) )
        return NO;
    return value > minimum;
}

BOOL FBIsValueGreaterThan(CGFloat value, CGFloat minimum)
{
    return FBIsValueGreaterThanWithOptions(value, minimum, FBTangentClosenessThreshold);
}

BOOL FBIsValueLessThan(CGFloat value, CGFloat maximum)
{
    if ( FBAreValuesCloseWithOptions(value, maximum, FBTangentClosenessThreshold) )
        return NO;
    return value < maximum;
}

BOOL FBIsValueGreaterThanEqual(CGFloat value, CGFloat minimum)
{
    if ( FBAreValuesCloseWithOptions(value, minimum, FBTangentClosenessThreshold) )
        return YES;
    return value >= minimum;
}

static BOOL FBIsValueLessThanEqualWithOptions(CGFloat value, CGFloat maximum, CGFloat threshold)
{
    if ( FBAreValuesCloseWithOptions(value, maximum, threshold) )
        return YES;
    return value <= maximum;
}

BOOL FBIsValueLessThanEqual(CGFloat value, CGFloat maximum)
{
    return FBIsValueLessThanEqualWithOptions(value, maximum, FBTangentClosenessThreshold);
}

BOOL FBAngleRangeContainsAngle(FBAngleRange range, CGFloat angle)
{
    if ( range.minimum <= range.maximum )
        return FBIsValueGreaterThan(angle, range.minimum) && FBIsValueLessThan(angle, range.maximum);
    
    // The range wraps around 0. See if the angle falls in the first half
    if ( FBIsValueGreaterThan(angle, range.minimum) && angle <= FB2PI )
        return YES;
    
    return angle >= 0.0 && FBIsValueLessThan(angle, range.maximum);
}

//////////////////////////////////////////////////////////////////////////////////
// Parameter ranges
//
FBRange FBRangeMake(CGFloat minimum, CGFloat maximum)
{
    FBRange range = { minimum, maximum };
    return range;
}

BOOL FBRangeHasConverged(FBRange range, NSUInteger places)
{
    CGFloat factor = pow(10.0, places);
    NSInteger minimum = (NSInteger)(range.minimum * factor);
    NSInteger maxiumum = (NSInteger)(range.maximum * factor);
    return minimum == maxiumum;
}

CGFloat FBRangeGetSize(FBRange range)
{
    return range.maximum - range.minimum;
}

CGFloat FBRangeAverage(FBRange range)
{
    return (range.minimum + range.maximum) / 2.0;
}

CGFloat FBRangeScaleNormalizedValue(FBRange range, CGFloat value)
{
    return (range.maximum - range.minimum) * value + range.minimum;
}

FBRange FBRangeUnion(FBRange range1, FBRange range2)
{
    FBRange range = { MIN(range1.minimum, range2.minimum), MAX(range1.maximum, range2.maximum) };
    return range;
}

BOOL FBAreTangentsAmbigious(CGPoint edge1Tangents[2], CGPoint edge2Tangents[2])
{
    CGPoint normalEdge1[2] = { FBNormalizePoint(edge1Tangents[0]), FBNormalizePoint(edge1Tangents[1]) };
    CGPoint normalEdge2[2] = { FBNormalizePoint(edge2Tangents[0]), FBNormalizePoint(edge2Tangents[1]) };
    
    return FBArePointsCloseWithOptions(normalEdge1[0], normalEdge2[0], FBTangentClosenessThreshold) || FBArePointsCloseWithOptions(normalEdge1[0], normalEdge2[1], FBTangentClosenessThreshold) || FBArePointsCloseWithOptions(normalEdge1[1], normalEdge2[0], FBTangentClosenessThreshold) || FBArePointsCloseWithOptions(normalEdge1[1], normalEdge2[1], FBTangentClosenessThreshold);
}

BOOL FBTangentsCross(CGPoint edge1Tangents[2], CGPoint edge2Tangents[2])
{    
    // Calculate angles for the tangents
    CGFloat edge1Angles[] = { PolarAngle(edge1Tangents[0]), PolarAngle(edge1Tangents[1]) };
    CGFloat edge2Angles[] = { PolarAngle(edge2Tangents[0]), PolarAngle(edge2Tangents[1]) };
    
    // Count how many times edge2 angles appear between the self angles
    FBAngleRange range1 = FBAngleRangeMake(edge1Angles[0], edge1Angles[1]);
    NSUInteger rangeCount1 = 0;
    if ( FBAngleRangeContainsAngle(range1, edge2Angles[0]) )
        rangeCount1++;
    if ( FBAngleRangeContainsAngle(range1, edge2Angles[1]) )
        rangeCount1++;
    
    // Count how many times self angles appear between the edge2 angles
    FBAngleRange range2 = FBAngleRangeMake(edge1Angles[1], edge1Angles[0]);
    NSUInteger rangeCount2 = 0;
    if ( FBAngleRangeContainsAngle(range2, edge2Angles[0]) )
        rangeCount2++;
    if ( FBAngleRangeContainsAngle(range2, edge2Angles[1]) )
        rangeCount2++;
    
    // If each pair of angles split the other two, then the edges cross.
    return rangeCount1 == 1 && rangeCount2 == 1;
}


BOOL FBLineBoundsMightOverlap(CGRect bounds1, CGRect bounds2)
{
    CGFloat left = MAX(NSMinX(bounds1), NSMinX(bounds2));
    CGFloat right = MIN(NSMaxX(bounds1), NSMaxX(bounds2));
    if ( FBIsValueGreaterThanWithOptions(left, right, FBBoundsClosenessThreshold) )
        return NO; // no horizontal overlap
    CGFloat top = MAX(NSMinY(bounds1), NSMinY(bounds2));
    CGFloat bottom = MIN(NSMaxY(bounds1), NSMaxY(bounds2));
    return FBIsValueLessThanEqualWithOptions(top, bottom, FBBoundsClosenessThreshold);
}
