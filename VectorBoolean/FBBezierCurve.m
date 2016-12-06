//
//  FBBezierCurve.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/6/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierCurve.h"
#import "NSBezierPath+Utilities.h"
#import "FBGeometry.h"
#import "FBBezierCurveLength.h"
#import "FBNormalizedLine.h"
#import "FBConvexHull.h"
#import "FBBezierCurveHelper.h"
#import "FBBezierIntersection.h"
#import "FBBezierIntersectRange.h"

#pragma mark FBBezierCurve Private Interface

@interface FBBezierCurve ()

+ (id) bezierCurveWithBezierCurveData:(FBBezierCurveData)data;
- (id) initWithBezierCurveData:(FBBezierCurveData)data;

- (CGFloat) refineParameter:(CGFloat)parameter forPoint:(CGPoint)point;

@property (readonly) FBBezierCurveData data;

@end

#pragma mark FBBezierCurveData

static const CGFloat FBBezierCurveDataInvalidLength = -1.0;
static const BOOL FBBezierCurveDataInvalidIsPoint = -1;

static FBBezierCurveData FBBezierCurveDataMake(CGPoint endPoint1, CGPoint controlPoint1, CGPoint controlPoint2, CGPoint endPoint2, BOOL isStraightLine)
{
    FBBezierCurveData data = {endPoint1, controlPoint1, controlPoint2, endPoint2, isStraightLine, FBBezierCurveDataInvalidLength, CGRectZero, FBBezierCurveDataInvalidIsPoint, CGRectZero };
    return data;
}

static CGFloat FBBezierCurveDataGetLengthAtParameter(FBBezierCurveData* me, CGFloat parameter)
{
    // Use the cached value if at all possible
    if ( parameter == 1.0 && me->length != FBBezierCurveDataInvalidLength )
        return me->length;
    
    // If it's a line, use that equation instead
    CGFloat length = FBBezierCurveDataInvalidLength;
    if ( me->isStraightLine )
        length = FBDistanceBetweenPoints(me->endPoint1, me->endPoint2) * parameter;
    else
        length = FBGaussQuadratureComputeCurveLengthForCubic(parameter, 12, me->endPoint1, me->controlPoint1, me->controlPoint2, me->endPoint2);
    
    // If possible, update our cache
    if ( parameter == 1.0 )
        me->length = length;
    
    return length;
}

static CGFloat FBBezierCurveDataGetLength(FBBezierCurveData* me)
{
    return FBBezierCurveDataGetLengthAtParameter(me, 1.0);
}

static CGPoint FBBezierCurveDataPointAtParameter(FBBezierCurveData me, CGFloat parameter, FBBezierCurveData *leftBezierCurve, FBBezierCurveData *rightBezierCurve)
{
    // This method is a simple wrapper around the BezierWithPoints() helper function. It computes the 2D point at the given parameter,
    //  and (optionally) the resulting curves that splitting at the parameter would create.
    
    CGPoint points[4] = { me.endPoint1, me.controlPoint1, me.controlPoint2, me.endPoint2 };
    CGPoint leftCurve[4] = {};
    CGPoint rightCurve[4] = {};
    
    CGPoint point = BezierWithPoints(3, points, parameter, leftCurve, rightCurve);
    
    if ( leftBezierCurve != nil ) {
        *leftBezierCurve = FBBezierCurveDataMake(leftCurve[0], leftCurve[1], leftCurve[2], leftCurve[3], me.isStraightLine);
	}
    if ( rightBezierCurve != nil ) {
        *rightBezierCurve = FBBezierCurveDataMake(rightCurve[0], rightCurve[1], rightCurve[2], rightCurve[3], me.isStraightLine);
	}
    return point;
}

static FBBezierCurveData FBBezierCurveDataSubcurveWithRange(FBBezierCurveData me, FBRange range)
{
    // Return a bezier curve representing the parameter range specified. We do this by splitting
    //  twice: once on the minimum, the splitting the result of that on the maximum.
    FBBezierCurveData upperCurve = {};
    FBBezierCurveDataPointAtParameter(me, range.minimum, nil, &upperCurve);
    if ( range.minimum == 1.0 )
        return upperCurve; // avoid the divide by zero below
    // We need to adjust the maximum parameter to fit on the new curve before we split again
    CGFloat adjustedMaximum = (range.maximum - range.minimum) / (1.0 - range.minimum);
    
    FBBezierCurveData lowerCurve = {};
    FBBezierCurveDataPointAtParameter(upperCurve, adjustedMaximum, &lowerCurve, nil);
    return lowerCurve;
}

static FBNormalizedLine FBBezierCurveDataRegularFatLineBounds(FBBezierCurveData me, FBRange *range)
{
    // Create the fat line based on the end points
    FBNormalizedLine line = FBNormalizedLineMake(me.endPoint1, me.endPoint2);
    
    // Compute the bounds of the fat line. The fat line bounds should entirely encompass the
    //  bezier curve. Since we know the convex hull entirely compasses the curve, just take
    //  all four points that define this cubic bezier curve. Compute the signed distances of
    //  each of the end and control points from the fat line, and that will give us the bounds.
    
    // In this case, we know that the end points are on the line, thus their distances will be 0.
    //  So we can skip computing those and just use 0.
    CGFloat controlPoint1Distance = FBNormalizedLineDistanceFromPoint(line, me.controlPoint1);
    CGFloat controlPoint2Distance = FBNormalizedLineDistanceFromPoint(line, me.controlPoint2);
    CGFloat min = MIN(controlPoint1Distance, MIN(controlPoint2Distance, 0.0));
    CGFloat max = MAX(controlPoint1Distance, MAX(controlPoint2Distance, 0.0));
    
    *range = FBRangeMake(min, max);
    
    return line;
}

static FBNormalizedLine FBBezierCurveDataPerpendicularFatLineBounds(FBBezierCurveData me, FBRange *range)
{
    // Create a fat line that's perpendicular to the line created by the two end points.
    CGPoint normal = FBLineNormal(me.endPoint1, me.endPoint2);
    CGPoint startPoint = FBLineMidpoint(me.endPoint1, me.endPoint2);
    CGPoint endPoint = FBAddPoint(startPoint, normal);
    FBNormalizedLine line = FBNormalizedLineMake(startPoint, endPoint);
    
    // Compute the bounds of the fat line. The fat line bounds should entirely encompass the
    //  bezier curve. Since we know the convex hull entirely compasses the curve, just take
    //  all four points that define this cubic bezier curve. Compute the signed distances of
    //  each of the end and control points from the fat line, and that will give us the bounds.
    CGFloat controlPoint1Distance = FBNormalizedLineDistanceFromPoint(line, me.controlPoint1);
    CGFloat controlPoint2Distance = FBNormalizedLineDistanceFromPoint(line, me.controlPoint2);
    CGFloat point1Distance = FBNormalizedLineDistanceFromPoint(line, me.endPoint1);
    CGFloat point2Distance = FBNormalizedLineDistanceFromPoint(line, me.endPoint2);
    
    CGFloat min = MIN(controlPoint1Distance, MIN(controlPoint2Distance, MIN(point1Distance, point2Distance)));
    CGFloat max = MAX(controlPoint1Distance, MAX(controlPoint2Distance, MAX(point1Distance, point2Distance)));
    
    *range = FBRangeMake(min, max);
    
    return line;
}

static FBRange FBBezierCurveDataClipWithFatLine(FBBezierCurveData me, FBNormalizedLine fatLine, FBRange bounds)
{
    // This method computes the range of self that could possibly intersect with the fat line passed in (and thus with the curve enclosed by the fat line).
    //  To do that, we first compute the signed distance of all our points (end and control) from the fat line, and map those onto a bezier curve at
    //  evenly spaced intervals from [0..1]. The parts of the distance bezier that fall inside of the fat line bounds, correspond to the parts of ourself
    //  that could potentially intersect with the other curve. Ideally, we'd calculate where the distance bezier intersected the horizontal lines representing
    //  the fat line bounds. However, computing those intersections is hard and costly. So instead we'll compute the convex hull, and intersect those lines
    //  with the fat line bounds. The intersection with the lowest x coordinate will be the minimum, and the intersection with the highest x coordinate will
    //  be the maximum.
    
    // The convex hull (for cubic beziers) is the four points that define the curve. A useful property of the convex hull is that the entire curve lies
    //  inside of it.
    
    // First calculate bezier curve points distance from the fat line that's clipping us
    CGPoint distanceBezierPoints[] = {
        CGPointMake(0, FBNormalizedLineDistanceFromPoint(fatLine, me.endPoint1)),
        CGPointMake(1.0/3.0, FBNormalizedLineDistanceFromPoint(fatLine, me.controlPoint1)),
        CGPointMake(2.0/3.0, FBNormalizedLineDistanceFromPoint(fatLine, me.controlPoint2)),
        CGPointMake(1.0, FBNormalizedLineDistanceFromPoint(fatLine, me.endPoint2))
    };
    
    NSUInteger convexHullLength = 0;
    CGPoint convexHull[8] = {};
    FBConvexHullBuildFromPoints(distanceBezierPoints, convexHull, &convexHullLength);
    
    // Find intersections of convex hull with the fat line bounds
    FBRange range = FBRangeMake(1.0, 0.0);
    for (NSUInteger i = 0; i < convexHullLength; i++) {
        // Pull out the current line on the convex hull
        NSUInteger indexOfNext = i < (convexHullLength - 1) ? i + 1 : 0;
        CGPoint startPoint = convexHull[i];
        CGPoint endPoint = convexHull[indexOfNext];
        CGPoint intersectionPoint = CGPointZero;
        
        // See if the segment of the convex hull intersects with the minimum fat line bounds
        if ( LineIntersectsHorizontalLine(startPoint, endPoint, bounds.minimum, &intersectionPoint) ) {
            if ( intersectionPoint.x < range.minimum )
                range.minimum = intersectionPoint.x;
            if ( intersectionPoint.x > range.maximum )
                range.maximum = intersectionPoint.x;
        }
        
        // See if this segment of the convex hull intersects with the maximum fat line bounds
        if ( LineIntersectsHorizontalLine(startPoint, endPoint, bounds.maximum, &intersectionPoint) ) {
            if ( intersectionPoint.x < range.minimum )
                range.minimum = intersectionPoint.x;
            if ( intersectionPoint.x > range.maximum )
                range.maximum = intersectionPoint.x;
        }
        
        // We want to be able to refine t even if the convex hull lies completely inside the bounds. This
        //  also allows us to be able to use range of [1..0] as a sentinel value meaning the convex hull
        //  lies entirely outside of bounds, and the curves don't intersect.
        if ( startPoint.y < bounds.maximum && startPoint.y > bounds.minimum ) {
            if ( startPoint.x < range.minimum )
                range.minimum = startPoint.x;
            if ( startPoint.x > range.maximum )
                range.maximum = startPoint.x;
        }
    }
    
    // Check for bad values
    if ( range.minimum == INFINITY || range.minimum == NAN || range.maximum == INFINITY || range.maximum == NAN )
        range = FBRangeMake(0, 1); // equivalent to: something went wrong, so I don't know
    
    return range;
}

static FBBezierCurveData FBBezierCurveDataBezierClipWithBezierCurve(FBBezierCurveData me, FBBezierCurveData curve, FBBezierCurveData originalCurve, FBRange *originalRange, BOOL *intersects)
{
    // This method does the clipping of self. It removes the parts of self that we can determine don't intersect
    //  with curve. It'll return the clipped version of self, update originalRange which corresponds to the range
    //  on the original curve that the return value represents. Finally, it'll set the intersects out parameter
    //  to yes or no depending on if the curves intersect or not.
    
    // Clipping works as follows:
    //  Draw a line through the two endpoints of the other curve, which we'll call the fat line. Measure the
    //  signed distance between the control points on the other curve and the fat line. The distance from the line
    //  will give us the fat line bounds. Any part of our curve that lies further away from the fat line than the
    //  fat line bounds we know can't intersect with the other curve, and thus can be removed.
    
    // We actually use two different fat lines. The first one uses the end points of the other curve, and the second
    //  one is perpendicular to the first. Most of the time, the first fat line will clip off more, but sometimes the
    //  second proves to be a better fat line in that it clips off more. We use both in order to converge more quickly.
    
    // Compute the regular fat line using the end points, then compute the range that could still possibly intersect
    //  with the other curve
    FBRange fatLineBounds = {};
    FBNormalizedLine fatLine = FBBezierCurveDataRegularFatLineBounds(curve, &fatLineBounds);
    FBRange regularClippedRange = FBBezierCurveDataClipWithFatLine(me, fatLine, fatLineBounds);
    // A range of [1, 0] is a special sentinel value meaning "they don't intersect". If they don't, bail early to save time
    if ( regularClippedRange.minimum == 1.0 && regularClippedRange.maximum == 0.0 ) {
        *intersects = NO;
        return me;
    }
    
    // Just in case the regular fat line isn't good enough, try the perpendicular one
    FBRange perpendicularLineBounds = {};
    FBNormalizedLine perpendicularLine = FBBezierCurveDataPerpendicularFatLineBounds(curve, &perpendicularLineBounds);
    FBRange perpendicularClippedRange = FBBezierCurveDataClipWithFatLine(me, perpendicularLine, perpendicularLineBounds);
    if ( perpendicularClippedRange.minimum == 1.0 && perpendicularClippedRange.maximum == 0.0 ) {
        *intersects = NO;
        return me;
    }
    
    // Combine to form Voltron. Take the intersection of the regular fat line range and the perpendicular one.
    FBRange clippedRange = FBRangeMake(MAX(regularClippedRange.minimum, perpendicularClippedRange.minimum), MIN(regularClippedRange.maximum, perpendicularClippedRange.maximum));
    
    // Right now the clipped range is relative to ourself, not the original curve. So map the newly clipped range onto the original range
    FBRange newRange = FBRangeMake(FBRangeScaleNormalizedValue(*originalRange, clippedRange.minimum), FBRangeScaleNormalizedValue(*originalRange, clippedRange.maximum));
    *originalRange = newRange;
    *intersects = YES;
    
    // Actually divide the curve, but be sure to use the original curve. This helps with errors building up.
    return FBBezierCurveDataSubcurveWithRange(originalCurve, *originalRange);
}

static BOOL FBBezierCurveDataIsPoint(FBBezierCurveData *me)
{
    // If the two end points are close together, then we're a point. Ignore the control
    //  points.
    static const CGFloat FBClosenessThreshold = 1e-5;
    
    if ( me->isPoint != FBBezierCurveDataInvalidIsPoint )
        return me->isPoint;
    
    me->isPoint = FBArePointsCloseWithOptions(me->endPoint1, me->endPoint2, FBClosenessThreshold)
        && FBArePointsCloseWithOptions(me->endPoint1, me->controlPoint1, FBClosenessThreshold)
        && FBArePointsCloseWithOptions(me->endPoint1, me->controlPoint2, FBClosenessThreshold);
    
    return me->isPoint;
}

static CGRect FBBezierCurveDataBoundingRect(FBBezierCurveData *me)
{
    // Use the cache if we have one
    if ( !CGRectEqualToRect(me->boundingRect, CGRectZero) )
        return me->boundingRect;

    CGFloat left = MIN(me->endPoint1.x, MIN(me->controlPoint1.x, MIN(me->controlPoint2.x, me->endPoint2.x)));
    CGFloat top = MIN(me->endPoint1.y, MIN(me->controlPoint1.y, MIN(me->controlPoint2.y, me->endPoint2.y)));
    CGFloat right = MAX(me->endPoint1.x, MAX(me->controlPoint1.x, MAX(me->controlPoint2.x, me->endPoint2.x)));
    CGFloat bottom = MAX(me->endPoint1.y, MAX(me->controlPoint1.y, MAX(me->controlPoint2.y, me->endPoint2.y)));
    
    me->boundingRect = CGRectMake(left, top, right - left, bottom - top);
    
    return me->boundingRect;
}

static CGRect FBBezierCurveDataBounds(FBBezierCurveData* me)
{
    // Use the cache if we have one
    if ( !CGRectEqualToRect(me->bounds, CGRectZero) )
        return me->bounds;
    
    CGRect bounds = CGRectZero;
    
    if ( me->isStraightLine ) {
        CGPoint topLeft = me->endPoint1;
        CGPoint bottomRight = topLeft;
        FBExpandBoundsByPoint(&topLeft, &bottomRight, me->endPoint2);

        bounds = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
    } else {
        // Start with the end points
        CGPoint topLeft = FBBezierCurveDataPointAtParameter(*me, 0, nil, nil);
        CGPoint bottomRight = topLeft;
        CGPoint lastPoint = FBBezierCurveDataPointAtParameter(*me, 1, nil, nil);
        FBExpandBoundsByPoint(&topLeft, &bottomRight, lastPoint);
        
        // Find the roots, which should be the extremities
        CGFloat xRoots[] = {0.0, 0.0};
        NSUInteger xRootsCount = 0;
        FBComputeCubicFirstDerivativeRoots(me->endPoint1.x, me->controlPoint1.x, me->controlPoint2.x, me->endPoint2.x, xRoots, &xRootsCount);
        for (NSUInteger i = 0; i < xRootsCount; i++) {
            CGFloat t = xRoots[i];
            if ( t < 0 || t > 1 )
                continue;
            
            CGPoint location = FBBezierCurveDataPointAtParameter(*me, t, nil, nil);
            FBExpandBoundsByPoint(&topLeft, &bottomRight, location);
        }
        
        CGFloat yRoots[] = {0.0, 0.0};
        NSUInteger yRootsCount = 0;
        FBComputeCubicFirstDerivativeRoots(me->endPoint1.y, me->controlPoint1.y, me->controlPoint2.y, me->endPoint2.y, yRoots, &yRootsCount);
        for (NSUInteger i = 0; i < yRootsCount; i++) {
            CGFloat t = yRoots[i];
            if ( t < 0 || t > 1 )
                continue;
            
            CGPoint location = FBBezierCurveDataPointAtParameter(*me, t, nil, nil);
            FBExpandBoundsByPoint(&topLeft, &bottomRight, location);
        }
        
        bounds = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
    }
    
    // Cache the value
    me->bounds = bounds;
    
    return me->bounds;
}

static void FBBezierCurveDataRefineIntersectionsOverIterations(NSUInteger iterations, FBRange *usRange, FBRange *themRange, FBBezierCurveData originalUs, FBBezierCurveData originalThem, FBBezierCurveData us, FBBezierCurveData them, FBBezierCurveData nonpointUs, FBBezierCurveData nonpointThem)
{
    for (NSUInteger i = 0; i < iterations; i++) {
        BOOL intersects = NO;
        us = FBBezierCurveDataBezierClipWithBezierCurve(us, them, originalUs, usRange, &intersects);
        if ( !intersects )
            us = FBBezierCurveDataBezierClipWithBezierCurve(nonpointUs, nonpointThem, originalUs, usRange, &intersects);
        them = FBBezierCurveDataBezierClipWithBezierCurve(them, us, originalThem, themRange, &intersects);
        if ( !intersects )
            them = FBBezierCurveDataBezierClipWithBezierCurve(nonpointThem, nonpointUs, originalThem, themRange, &intersects);
        if ( !FBBezierCurveDataIsPoint(&them) )
            nonpointThem = them;
        if ( !FBBezierCurveDataIsPoint(&us) )
            nonpointUs = us;
    }
}


static FBBezierCurveData FBBezierCurveDataClipLineOriginalCurve(FBBezierCurveData me, FBBezierCurveData originalCurve, FBBezierCurveData curve, FBRange *originalRange, FBBezierCurveData otherCurve, BOOL *intersects)
{
    CGFloat themOnUs1 = FBParameterOfPointOnLine(curve.endPoint1, curve.endPoint2, otherCurve.endPoint1);
    CGFloat themOnUs2 = FBParameterOfPointOnLine(curve.endPoint1, curve.endPoint2, otherCurve.endPoint2);
    FBRange clippedRange = FBRangeMake(MAX(0, MIN(themOnUs1, themOnUs2)), MIN(1, MAX(themOnUs1, themOnUs2)));
    if ( clippedRange.minimum > clippedRange.maximum ) {
        *intersects = NO;
        return curve; // No intersection
    }
    
    // Right now the clipped range is relative to ourself, not the original curve. So map the newly clipped range onto the original range
    FBRange newRange = FBRangeMake(FBRangeScaleNormalizedValue(*originalRange, clippedRange.minimum), FBRangeScaleNormalizedValue(*originalRange, clippedRange.maximum));
    *originalRange = newRange;
    *intersects = YES;
    
    // Actually divide the curve, but be sure to use the original curve. This helps with errors building up.
    return FBBezierCurveDataSubcurveWithRange(originalCurve, *originalRange);
}

static BOOL FBBezierCurveDataCheckLinesForOverlap(FBBezierCurveData me, FBRange *usRange, FBRange *themRange, FBBezierCurveData originalUs, FBBezierCurveData originalThem, FBBezierCurveData *us, FBBezierCurveData *them)
{
    // First see if its possible for them to overlap at all
    if ( !FBLineBoundsMightOverlap(FBBezierCurveDataBounds(us), FBBezierCurveDataBounds(them)) )
        return NO;
    
    // Are all 4 points in a single line?
    CGFloat errorThreshold = 1e-7;    
    BOOL isColinear = FBAreValuesCloseWithOptions(CounterClockwiseTurn((*us).endPoint1, (*us).endPoint2, (*them).endPoint1), 0.0, errorThreshold)
                    && FBAreValuesCloseWithOptions(CounterClockwiseTurn((*us).endPoint1, (*us).endPoint2, (*them).endPoint2), 0.0, errorThreshold);
    if ( !isColinear )
        return NO;
    
    BOOL intersects = NO;
    *us = FBBezierCurveDataClipLineOriginalCurve(me, originalUs, *us, usRange, *them, &intersects);
    if ( !intersects )
        return NO;

    *them = FBBezierCurveDataClipLineOriginalCurve(me, originalThem, *them, themRange, *us, &intersects);
    
    return intersects;
}

static void FBBezierCurveDataConvertSelfAndPoint(FBBezierCurveData me, CGPoint point, CGPoint *bezierPoints)
{
    CGPoint selfPoints[4] = { me.endPoint1, me.controlPoint1, me.controlPoint2, me.endPoint2 };
    
    // c[i] in the paper
    CGPoint distanceFromPoint[4] = {};
    for (NSUInteger i = 0; i < 4; i++)
        distanceFromPoint[i] = FBSubtractPoint(selfPoints[i], point);
        
        // d[i] in the paper
        CGPoint weightedDelta[3] = {};
        for (NSUInteger i = 0; i < 3; i++)
            weightedDelta[i] = FBScalePoint(FBSubtractPoint(selfPoints[i + 1], selfPoints[i]), 3);
            
            // Precompute the dot product of distanceFromPoint and weightedDelta in order to speed things up
            CGFloat precomputedTable[3][4] = {};
            for (NSUInteger row = 0; row < 3; row++) {
                for (NSUInteger column = 0; column < 4; column++)
                    precomputedTable[row][column] = FBDotMultiplyPoint(weightedDelta[row], distanceFromPoint[column]);
            }
    
    // Precompute some of the values to speed things up
    static const CGFloat FBZ[3][4] = {
        {1.0, 0.6, 0.3, 0.1},
        {0.4, 0.6, 0.6, 0.4},
        {0.1, 0.3, 0.6, 1.0}
    };
    
    // Set the x values of the bezier points
    for (NSUInteger i = 0; i < 6; i++)
        bezierPoints[i] = CGPointMake((CGFloat)i / 5.0, 0);
        
        // Finally set the y values of the bezier points
        NSInteger n = 3;
        NSInteger m = n - 1;
        for (NSInteger k = 0; k <= (n + m); k++) {
            NSInteger lowerBound = MAX(0, k - m);
            NSInteger upperBound = MIN(k, n);
            for (NSInteger i = lowerBound; i <= upperBound; i++) {
                NSInteger j = k - i;
                bezierPoints[i + j].y += precomputedTable[j][i] * FBZ[j][i];
            }
        }
}

static FBBezierCurveLocation FBBezierCurveDataClosestLocationToPoint(FBBezierCurveData me, CGPoint point)
{
    CGPoint bezierPoints[6] = {};
    FBBezierCurveDataConvertSelfAndPoint(me, point, bezierPoints);
    
    __block CGFloat distance = FBDistanceBetweenPoints(me.endPoint1, point);
    __block CGFloat parameter = 0.0;

    FBFindBezierRoots(bezierPoints, 5, ^(CGFloat root) {
        CGPoint location = FBBezierCurveDataPointAtParameter(me, root, nil, nil);
        CGFloat theDistance = FBDistanceBetweenPoints(location, point);
        if ( theDistance < distance ) {
            distance = theDistance;
            parameter = root;
        }        
    });
        
    CGFloat lastDistance = FBDistanceBetweenPoints(me.endPoint2, point);
    if ( lastDistance < distance ) {
        distance = lastDistance;
        parameter = 1.0;
    }
    
    FBBezierCurveLocation location = {};
    location.parameter = parameter;
    location.distance = distance;
    return location;
}


static BOOL FBBezierCurveDataIsEqualWithOptions(FBBezierCurveData me, FBBezierCurveData other, CGFloat threshold)
{
    if ( FBBezierCurveDataIsPoint(&me) || FBBezierCurveDataIsPoint(&other) )
        return NO;
    if ( me.isStraightLine != other.isStraightLine )
        return NO;
    
    if ( me.isStraightLine )
        return FBArePointsCloseWithOptions(me.endPoint1, other.endPoint1, threshold) && FBArePointsCloseWithOptions(me.endPoint2, other.endPoint2, threshold);
    return FBArePointsCloseWithOptions(me.endPoint1, other.endPoint1, threshold) && FBArePointsCloseWithOptions(me.controlPoint1, other.controlPoint1, threshold) && FBArePointsCloseWithOptions(me.controlPoint2, other.controlPoint2, threshold) && FBArePointsCloseWithOptions(me.endPoint2, other.endPoint2, threshold);
}

static BOOL FBBezierCurveDataAreCurvesEqual(FBBezierCurveData me, FBBezierCurveData other)
{
    if ( FBBezierCurveDataIsPoint(&me) || FBBezierCurveDataIsPoint(&other) )
        return NO;
    if ( me.isStraightLine != other.isStraightLine )
        return NO;

    
    static const CGFloat endPointThreshold = 1e-4;
    static const CGFloat controlPointThreshold = 1e-1;
    
    if ( me.isStraightLine )
        return FBArePointsCloseWithOptions(me.endPoint1, other.endPoint1, endPointThreshold) && FBArePointsCloseWithOptions(me.endPoint2, other.endPoint2, endPointThreshold);

    return FBArePointsCloseWithOptions(me.endPoint1, other.endPoint1, endPointThreshold)
        && FBArePointsCloseWithOptions(me.controlPoint1, other.controlPoint1, controlPointThreshold)
        && FBArePointsCloseWithOptions(me.controlPoint2, other.controlPoint2, controlPointThreshold)
        && FBArePointsCloseWithOptions(me.endPoint2, other.endPoint2, endPointThreshold);
}

static BOOL FBBezierCurveDataIsEqual(FBBezierCurveData me, FBBezierCurveData other)
{
    return FBBezierCurveDataIsEqualWithOptions(me, other, 1e-10);
}

static FBBezierCurveData FBBezierCurveDataReversed(FBBezierCurveData me)
{
    return FBBezierCurveDataMake(me.endPoint2, me.controlPoint2, me.controlPoint1, me.endPoint1, me.isStraightLine);
}

static BOOL FBBezierCurveDataCheckForOverlapRange(FBBezierCurveData me, FBBezierIntersectRange **intersectRange, FBRange *usRange, FBRange *themRange, FBBezierCurve* originalUs, FBBezierCurve* originalThem, FBBezierCurveData us, FBBezierCurveData them)
{
    if ( FBBezierCurveDataAreCurvesEqual(us, them) ) {
        if ( intersectRange != nil ) {
            *intersectRange = [FBBezierIntersectRange intersectRangeWithCurve1:originalUs parameterRange1:*usRange curve2:originalThem parameterRange2:*themRange reversed:NO];
        }
        return YES;
    } else if ( FBBezierCurveDataAreCurvesEqual(us, FBBezierCurveDataReversed(them)) ) {
        if ( intersectRange != nil ) {
            *intersectRange = [FBBezierIntersectRange intersectRangeWithCurve1:originalUs parameterRange1:*usRange curve2:originalThem parameterRange2:*themRange reversed:YES];
        }
        return YES;
    }
    return NO;
}

static FBBezierCurveData FBBezierCurveDataFindPossibleOverlap(FBBezierCurveData me, FBBezierCurveData originalUs, FBBezierCurveData them, FBRange *possibleRange)
{
    FBBezierCurveLocation themOnUs1 = FBBezierCurveDataClosestLocationToPoint(originalUs, them.endPoint1);
    FBBezierCurveLocation themOnUs2 = FBBezierCurveDataClosestLocationToPoint(originalUs, them.endPoint2);
    FBRange range = FBRangeMake(MIN(themOnUs1.parameter, themOnUs2.parameter), MAX(themOnUs1.parameter, themOnUs2.parameter));
    *possibleRange = range;
    return FBBezierCurveDataSubcurveWithRange(originalUs, range);
}

static BOOL FBBezierCurveDataCheckCurvesForOverlapRange(FBBezierCurveData me, FBBezierIntersectRange **intersectRange, FBRange *usRange, FBRange *themRange, FBBezierCurve* originalUs, FBBezierCurve* originalThem, FBBezierCurveData us, FBBezierCurveData them)
{
    if ( FBBezierCurveDataCheckForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them) )
        return YES;
    
    FBRange usSubcurveRange = {};
    FBBezierCurveData usSubcurve = FBBezierCurveDataFindPossibleOverlap(me, originalUs.data, them, &usSubcurveRange);

    FBRange themSubcurveRange = {};
    FBBezierCurveData themSubcurve = FBBezierCurveDataFindPossibleOverlap(me, originalThem.data, us, &themSubcurveRange);

    CGFloat threshold = 1e-4;
    if ( FBBezierCurveDataIsEqualWithOptions(usSubcurve, themSubcurve, threshold) || FBBezierCurveDataIsEqualWithOptions(usSubcurve, FBBezierCurveDataReversed(themSubcurve), threshold) ) {
        *usRange = usSubcurveRange;
        *themRange = themSubcurveRange;
        return FBBezierCurveDataCheckForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, usSubcurve, themSubcurve);
    }
    
    return NO;
}

static void FBBezierCurveDataCheckNoIntersectionsForOverlapRange(FBBezierCurveData me, FBBezierIntersectRange **intersectRange, FBRange *usRange, FBRange *themRange, FBBezierCurve* originalUs, FBBezierCurve* originalThem, FBBezierCurveData us, FBBezierCurveData them, FBBezierCurveData nonpointUs, FBBezierCurveData nonpointThem)
{
    if ( us.isStraightLine && them.isStraightLine )
        FBBezierCurveDataCheckLinesForOverlap(me, usRange, themRange, originalUs.data, originalThem.data, &us, &them);
    
    FBBezierCurveDataCheckForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them);    
}

static BOOL FBBezierCurveDataCheckForStraightLineOverlap(FBBezierCurveData me, FBBezierIntersectRange **intersectRange, FBRange *usRange, FBRange *themRange, FBBezierCurve* originalUs, FBBezierCurve* originalThem, FBBezierCurveData us, FBBezierCurveData them, FBBezierCurveData nonpointUs, FBBezierCurveData nonpointThem)
{
    BOOL hasOverlap = NO;
    
    if ( us.isStraightLine && them.isStraightLine )
        hasOverlap = FBBezierCurveDataCheckLinesForOverlap(me, usRange, themRange, originalUs.data, originalThem.data, &us, &them);
    
    if ( hasOverlap )
        hasOverlap = FBBezierCurveDataCheckForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them);
        
    return hasOverlap;
}

static CGFloat FBBezierCurveDataRefineParameter(FBBezierCurveData me, CGFloat parameter, CGPoint point)
{
    // Use Newton's Method to refine our parameter. In general, that formula is:
    //
    //  parameter = parameter - f(parameter) / f'(parameter)
    //
    // In our case:
    //
    //  f(parameter) = (Q(parameter) - point) * Q'(parameter) = 0
    //
    // Where Q'(parameter) is tangent to the curve at Q(parameter) and orthogonal to [Q(parameter) - P]
    //
    // Taking the derivative gives us:
    //
    //  f'(parameter) = (Q(parameter) - point) * Q''(parameter) + Q'(parameter) * Q'(parameter)
    //
    
    CGPoint bezierPoints[4] = {me.endPoint1, me.controlPoint1, me.controlPoint2, me.endPoint2};
    
    // Compute Q(parameter)
    CGPoint qAtParameter = BezierWithPoints(3, bezierPoints, parameter, nil, nil);
    
    // Compute Q'(parameter)
    CGPoint qPrimePoints[3] = {};
    for (NSUInteger i = 0; i < 3; i++) {
        qPrimePoints[i].x = (bezierPoints[i + 1].x - bezierPoints[i].x) * 3.0;
        qPrimePoints[i].y = (bezierPoints[i + 1].y - bezierPoints[i].y) * 3.0;
    }
    CGPoint qPrimeAtParameter = BezierWithPoints(2, qPrimePoints, parameter, nil, nil);
    
    // Compute Q''(parameter)
    CGPoint qPrimePrimePoints[2] = {};
    for (NSUInteger i = 0; i < 2; i++) {
        qPrimePrimePoints[i].x = (qPrimePoints[i + 1].x - qPrimePoints[i].x) * 2.0;
        qPrimePrimePoints[i].y = (qPrimePoints[i + 1].y - qPrimePoints[i].y) * 2.0;
    }
    CGPoint qPrimePrimeAtParameter = BezierWithPoints(1, qPrimePrimePoints, parameter, nil, nil);
    
    // Compute f(parameter) and f'(parameter)
    CGPoint qMinusPoint = FBSubtractPoint(qAtParameter, point);
    CGFloat fAtParameter = FBDotMultiplyPoint(qMinusPoint, qPrimeAtParameter);
    CGFloat fPrimeAtParameter = FBDotMultiplyPoint(qMinusPoint, qPrimePrimeAtParameter) + FBDotMultiplyPoint(qPrimeAtParameter, qPrimeAtParameter);
    
    // Newton's method!
    return parameter - (fAtParameter / fPrimeAtParameter);
}

static FBBezierIntersectRange *FBBezierCurveDataMergeIntersectRange(FBBezierIntersectRange *intersectRange, FBBezierIntersectRange *otherIntersectRange)
{
    if ( otherIntersectRange == nil )
        return intersectRange;
    
    if ( intersectRange == nil )
        return otherIntersectRange;
    
    [intersectRange merge:otherIntersectRange];
    
    return intersectRange;
}

static BOOL FBBezierCurveDataIntersectionsWithStraightLines(FBBezierCurveData me, FBBezierCurveData curve, FBRange *usRange, FBRange *themRange, FBBezierCurve *originalUs, FBBezierCurve *originalThem, FBCurveIntersectionBlock outputBlock, BOOL *stop)
{
    if ( !me.isStraightLine || !curve.isStraightLine )
        return NO;
    
    CGPoint intersectionPoint = CGPointZero;
    BOOL intersects = FBLinesIntersect(me.endPoint1, me.endPoint2, curve.endPoint1, curve.endPoint2, &intersectionPoint);
    if ( !intersects )
        return NO;

    CGFloat meParameter = FBParameterOfPointOnLine(me.endPoint1, me.endPoint2, intersectionPoint);
    if ( FBIsValueLessThan(meParameter, 0.0) || FBIsValueGreaterThan(meParameter, 1.0) )
        return NO;

    CGFloat curveParameter = FBParameterOfPointOnLine(curve.endPoint1, curve.endPoint2, intersectionPoint);
    if ( FBIsValueLessThan(curveParameter, 0.0) || FBIsValueGreaterThan(curveParameter, 1.0) )
        return NO;
    
    outputBlock([FBBezierIntersection intersectionWithCurve1:originalUs parameter1:meParameter curve2:originalThem parameter2:curveParameter], stop);

    return YES;
}

static void FBBezierCurveDataIntersectionsWithBezierCurve(FBBezierCurveData me, FBBezierCurveData curve, FBRange *usRange, FBRange *themRange, FBBezierCurve *originalUs, FBBezierCurve *originalThem, FBBezierIntersectRange **intersectRange, NSUInteger depth, FBCurveIntersectionBlock outputBlock, BOOL *stop)
{
    // This is the main work loop. At a high level this method sits in a loop and removes sections (ranges) of the two bezier curves that it knows
    //  don't intersect (how it knows that is covered in the appropriate method). The idea is to whittle the curves down to the point where they
    //  do intersect. When the range where they intersect converges (i.e. matches to 6 decimal places) or there are more than 500 attempts, the loop
    //  stops. A special case is when we're not able to remove at least 20% of the curves on a given interation. In that case we assume there are likely
    //  multiple intersections, so we divide one of curves in half, and recurse on the two halves.
    
    static const NSUInteger places = 6; // How many decimals place to calculate the solution out to
    static const NSUInteger maxIterations = 500; // how many iterations to allow before we just give up
    static const NSUInteger maxDepth = 10; // how many recursive calls to allow before we just give up
    static const CGFloat minimumChangeNeeded = 0.20; // how much to clip off for a given iteration minimum before we subdivide the curve
    
    FBBezierCurveData us = me; // us is self, but clipped down to where the intersection is
    FBBezierCurveData them = curve; // them is the other curve we're intersecting with, but clipped down to where the intersection is
    FBBezierCurveData nonpointUs = us;
    FBBezierCurveData nonpointThem = them;
    
    
    // Horizontal and vertical lines are somewhat special cases, and the math doesn't always work out that great. For example, two vertical lines
    //  that overlap will kick out as intersecting at the endpoints. Try to detect that kind of overlap at the start.
    if ( FBBezierCurveDataCheckForStraightLineOverlap(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them, nonpointUs, nonpointThem) )
        return;
    if ( us.isStraightLine && them.isStraightLine ) {
        FBBezierCurveDataIntersectionsWithStraightLines(me, curve, usRange, themRange, originalUs, originalThem, outputBlock, stop);
        return;
    }
    
    FBBezierCurveData originalUsData = originalUs.data;
    FBBezierCurveData originalThemData = originalThem.data;
    
    // Don't check for convergence until we actually see if we intersect or not. i.e. Make sure we go through at least once, otherwise the results
    //  don't mean anything. Be sure to stop as soon as either range converges, otherwise calculations for the other range goes funky because one
    //  curve is essentially a point.
    NSUInteger iterations = 0;
    BOOL hadConverged = YES;
    while ( iterations < maxIterations && ((iterations == 0) || (!FBRangeHasConverged(*usRange, places) || !FBRangeHasConverged(*themRange, places))) ) {
        // Remember what the current range is so we can calculate how much it changed later
        FBRange previousUsRange = *usRange;
        FBRange previousThemRange = *themRange;
        
        // Remove the range from ourselves that doesn't intersect with them. If the other curve is already a point, use the previous iteration's
        //  copy of them so calculations still work.
        BOOL intersects = NO;
        if ( !FBBezierCurveDataIsPoint(&them) )
            nonpointThem = them;
        us = FBBezierCurveDataBezierClipWithBezierCurve(nonpointUs, nonpointThem, originalUsData, usRange, &intersects);
        if ( !intersects ) {
            FBBezierCurveDataCheckNoIntersectionsForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them, nonpointUs, nonpointThem);
            return; // If they don't intersect at all stop now
        }
        if ( iterations > 0 && (FBBezierCurveDataIsPoint(&us) || FBBezierCurveDataIsPoint(&them)) )
            break;
        
        // Remove the range of them that doesn't intersect with us
        if ( !FBBezierCurveDataIsPoint(&us) )
            nonpointUs = us;
        else if ( iterations == 0 )
            // If the first time through us was reduced to a point, then we're never going to know if the curves actually intersect,
            //  even if both ranges converge. The ranges can converge on the parameters on each respective curve that is closest to the
            //  other. But without being clipped to a smaller range the algorithm won't necessarily detect that they don't actually intersect
            hadConverged = NO;
        them = FBBezierCurveDataBezierClipWithBezierCurve(nonpointThem, nonpointUs, originalThemData, themRange, &intersects);
        if ( !intersects ) {
            FBBezierCurveDataCheckNoIntersectionsForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them, nonpointUs, nonpointThem); 
            return; // If they don't intersect at all stop now
        }
        if ( iterations > 0 && (FBBezierCurveDataIsPoint(&us) || FBBezierCurveDataIsPoint(&them)) )
            break;
        
        // See if either of curves ranges is reduced by less than 20%.
        CGFloat percentChangeInUs = (FBRangeGetSize(previousUsRange) - FBRangeGetSize(*usRange)) / FBRangeGetSize(previousUsRange);
        CGFloat percentChangeInThem = (FBRangeGetSize(previousThemRange) - FBRangeGetSize(*themRange)) / FBRangeGetSize(previousThemRange);
        BOOL didNotSplit = NO;
        if ( percentChangeInUs < minimumChangeNeeded && percentChangeInThem < minimumChangeNeeded ) {
            // We're not converging fast enough, likely because there are multiple intersections here.
            //  Or the curves are the same, check for that first            
            if ( FBBezierCurveDataCheckCurvesForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them) )
                return;
            
            // Divide and conquer. Divide the longer curve in half, and recurse
            if ( FBRangeGetSize(*usRange) > FBRangeGetSize(*themRange) ) {
                // Since our remaining range is longer, split the remains of us in half at the midway point
                FBRange usRange1 = FBRangeMake(usRange->minimum, (usRange->minimum + usRange->maximum) / 2.0);
                FBBezierCurveData us1 = FBBezierCurveDataSubcurveWithRange(originalUsData, usRange1);
                FBRange themRangeCopy1 = *themRange; // make a local copy because it'll get modified when we recurse
                
                FBRange usRange2 = FBRangeMake((usRange->minimum + usRange->maximum) / 2.0, usRange->maximum);
                FBBezierCurveData us2 = FBBezierCurveDataSubcurveWithRange(originalUsData, usRange2);
                FBRange themRangeCopy2 = *themRange; // make a local copy because it'll get modified when we recurse
                
                BOOL range1ConvergedAlready = FBRangeHasConverged(usRange1, places) && FBRangeHasConverged(*themRange, places);
                BOOL range2ConvergedAlready = FBRangeHasConverged(usRange2, places) && FBRangeHasConverged(*themRange, places);
                
                if ( !range1ConvergedAlready && !range2ConvergedAlready && depth < maxDepth ) {
                    // Compute the intersections between the two halves of us and them
                    FBBezierIntersectRange *leftIntersectRange = nil;
                    FBBezierCurveDataIntersectionsWithBezierCurve(us1, them, &usRange1, &themRangeCopy1, originalUs, originalThem, &leftIntersectRange, depth + 1, outputBlock, stop);
                    if ( intersectRange != nil )
                        *intersectRange = FBBezierCurveDataMergeIntersectRange(*intersectRange, leftIntersectRange);
                    if ( *stop )
                        return;
                    FBBezierIntersectRange *rightIntersectRange = nil;
                    FBBezierCurveDataIntersectionsWithBezierCurve(us2, them, &usRange2, &themRangeCopy2, originalUs, originalThem, &rightIntersectRange, depth + 1, outputBlock, stop);
                    if ( intersectRange != nil )
                        *intersectRange = FBBezierCurveDataMergeIntersectRange(*intersectRange, rightIntersectRange);
                    return;
                } else
                    didNotSplit = YES;
            } else {
                // Since their remaining range is longer, split the remains of them in half at the midway point
                FBRange themRange1 = FBRangeMake(themRange->minimum, (themRange->minimum + themRange->maximum) / 2.0);
                FBBezierCurveData them1 = FBBezierCurveDataSubcurveWithRange(originalThemData, themRange1);
                FBRange usRangeCopy1 = *usRange;  // make a local copy because it'll get modified when we recurse
                
                FBRange themRange2 = FBRangeMake((themRange->minimum + themRange->maximum) / 2.0, themRange->maximum);
                FBBezierCurveData them2 = FBBezierCurveDataSubcurveWithRange(originalThemData, themRange2);
                FBRange usRangeCopy2 = *usRange;  // make a local copy because it'll get modified when we recurse
                
                BOOL range1ConvergedAlready = FBRangeHasConverged(themRange1, places) && FBRangeHasConverged(*usRange, places);
                BOOL range2ConvergedAlready = FBRangeHasConverged(themRange2, places) && FBRangeHasConverged(*usRange, places);
                
                if ( !range1ConvergedAlready && !range2ConvergedAlready && depth < maxDepth ) {
                    // Compute the intersections between the two halves of them and us
                    FBBezierIntersectRange *leftIntersectRange = nil;
                    FBBezierCurveDataIntersectionsWithBezierCurve(us, them1, &usRangeCopy1, &themRange1, originalUs, originalThem, &leftIntersectRange, depth + 1, outputBlock, stop);
                    if ( intersectRange != nil )
                        *intersectRange = FBBezierCurveDataMergeIntersectRange(*intersectRange, leftIntersectRange);

                    if ( *stop )
                        return;
                    FBBezierIntersectRange *rightIntersectRange = nil;
                    FBBezierCurveDataIntersectionsWithBezierCurve(us, them2, &usRangeCopy2, &themRange2, originalUs, originalThem, &rightIntersectRange, depth + 1, outputBlock, stop);
                    if ( intersectRange != nil )
                        *intersectRange = FBBezierCurveDataMergeIntersectRange(*intersectRange, rightIntersectRange);

                    return;
                } else
                    didNotSplit = YES;
            }
            
            if ( didNotSplit && (FBRangeGetSize(previousUsRange) - FBRangeGetSize(*usRange) == 0) && (FBRangeGetSize(previousThemRange) - FBRangeGetSize(*themRange) == 0) ) {
                // We're not converging at _all_ and we can't split, so we need to bail out.
                return; // no intersections
            }
        }
        
        iterations++;
    }
    
    
    // It's possible that one of the curves has converged, but the other hasn't. Since the math becomes wonky once a curve becomes a point,
    //  the loop stops as soon as either curve converges. However for our purposes we need _both_ curves to converge; that is we need
    //  the parameter for each curve where they intersect. Fortunately, since one curve did converge we know the 2D point where they converge,
    //  plus we have a reasonable approximation for the parameter for the curve that didn't. That means we can use Newton's method to refine
    //  the parameter of the curve that did't converge.
    if ( !FBRangeHasConverged(*usRange, places) || !FBRangeHasConverged(*themRange, places) ) {
        // Maybe there's an overlap in here?
        if ( FBBezierCurveDataCheckCurvesForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, originalUsData, originalThemData) )
            return;

        // We bail out of the main loop as soon as we know things intersect, but before the math falls apart. Unfortunately sometimes this
        //  means we don't always get the best estimate of the parameters. Below we fall back to Netwon's method, but it's accuracy is
        //  dependant on our previous calculations. So here assume things intersect and just try to tighten up the parameters. If the
        //  math falls apart because everything's a point, that's OK since we already have a "reasonable" estimation of the parameters.
        FBBezierCurveDataRefineIntersectionsOverIterations(3, usRange, themRange, originalUsData, originalThemData, us, them, nonpointUs, nonpointThem);
        // Sometimes we need a little more precision. Be careful though, in that in some cases trying for more makes the math fall apart
        if ( !FBRangeHasConverged(*usRange, places) || !FBRangeHasConverged(*themRange, places) )
            FBBezierCurveDataRefineIntersectionsOverIterations(4, usRange, themRange, originalUsData, originalThemData, us, them, nonpointUs, nonpointThem);
    }    
    if ( FBRangeHasConverged(*usRange, places) && !FBRangeHasConverged(*themRange, places) ) {
        // Refine the them range since it didn't converge
        CGPoint intersectionPoint = FBBezierCurveDataPointAtParameter(originalUsData, FBRangeAverage(*usRange), nil, nil);
        CGFloat refinedParameter = FBRangeAverage(*themRange); // Although the range didn't converge, it should be a reasonable approximation which is all Newton needs
        for (NSUInteger i = 0; i < 3; i++) {
            refinedParameter = FBBezierCurveDataRefineParameter(originalThemData, refinedParameter, intersectionPoint);
            refinedParameter = MIN(themRange->maximum, MAX(themRange->minimum, refinedParameter));
        }
        themRange->minimum = refinedParameter;
        themRange->maximum = refinedParameter;
        hadConverged = NO;
    } else if ( !FBRangeHasConverged(*usRange, places) && FBRangeHasConverged(*themRange, places) ) {
        // Refine the us range since it didn't converge
        CGPoint intersectionPoint = FBBezierCurveDataPointAtParameter(originalThemData, FBRangeAverage(*themRange), nil, nil);
        CGFloat refinedParameter = FBRangeAverage(*usRange); // Although the range didn't converge, it should be a reasonable approximation which is all Newton needs
        for (NSUInteger i = 0; i < 3; i++) {
            refinedParameter = FBBezierCurveDataRefineParameter(originalUsData, refinedParameter, intersectionPoint);
            refinedParameter = MIN(usRange->maximum, MAX(usRange->minimum, refinedParameter));
        }
        usRange->minimum = refinedParameter;
        usRange->maximum = refinedParameter;
        hadConverged = NO;
    }
    
    // If it never converged and we stopped because of our loop max, assume overlap or something else. Bail.
    if ( (!FBRangeHasConverged(*usRange, places) || !FBRangeHasConverged(*themRange, places)) && iterations >= maxIterations ) {
        FBBezierCurveDataCheckForOverlapRange(me, intersectRange, usRange, themRange, originalUs, originalThem, us, them);
        return;
    }
    
    if ( !hadConverged ) {
        // Since one of them didn't converge, we need to make sure they actually intersect. Compute the point from both and compare
        CGPoint intersectionPoint = FBBezierCurveDataPointAtParameter(originalUsData, FBRangeAverage(*usRange), nil, nil);
        CGPoint checkPoint = FBBezierCurveDataPointAtParameter(originalThemData, FBRangeAverage(*themRange), nil, nil);
        if ( !FBArePointsCloseWithOptions(intersectionPoint, checkPoint, 1e-3) )
            return;
    }
    // Return the final intersection, which we represent by the original curves and the parameters where they intersect. The parameter values are useful
    //  later in the boolean operations, plus it allows us to do lazy calculations.
    outputBlock([FBBezierIntersection intersectionWithCurve1:originalUs parameter1:FBRangeAverage(*usRange) curve2:originalThem parameter2:FBRangeAverage(*themRange)], stop);
}

//////////////////////////////////////////////////////////////////////////////////
// FBBezierCurve
//
// The main purpose of this class is to compute the intersections of two bezier
//  curves. It does this using the bezier clipping algorithm, described in
//  "Curve intersection using Bezier clipping" by TW Sederberg and T Nishita.
//  http://cagd.cs.byu.edu/~tom/papers/bezclip.pdf
//

@implementation FBBezierCurve

@synthesize data=_data;

- (CGPoint) endPoint1
{
    return _data.endPoint1;
}

- (CGPoint) controlPoint1
{
    return _data.controlPoint1;
}

- (CGPoint) controlPoint2
{
    return _data.controlPoint2;
}

- (CGPoint) endPoint2
{
    return _data.endPoint2;
}

- (BOOL) isStraightLine
{
    return _data.isStraightLine;
}

+ (NSArray *) bezierCurvesFromBezierPath:(NSBezierPath *)path
{
    // Helper method to easily convert a bezier path into an array of FBBezierCurves. Very straight forward,
    //  only lines are a special case.
    
    CGPoint lastPoint = CGPointZero;
    NSMutableArray *bezierCurves = [NSMutableArray arrayWithCapacity:path.elementCount];
    
    for (NSUInteger i = 0; i < path.elementCount; i++) {
        NSBezierElement element = [path fb_elementAtIndex:i];
        
        switch (element.kind) {
            case NSMoveToBezierPathElement:
                lastPoint = element.point;
                break;
                
            case NSLineToBezierPathElement: {
                // Convert lines to bezier curves as well. Just set control point to be in the line formed
                //  by the end points
                [bezierCurves addObject:[FBBezierCurve bezierCurveWithLineStartPoint:lastPoint endPoint:element.point]];
                
                lastPoint = element.point;
                break;
            }
                
            case NSCurveToBezierPathElement:
                [bezierCurves addObject:[FBBezierCurve bezierCurveWithEndPoint1:lastPoint controlPoint1:element.controlPoints[0] controlPoint2:element.controlPoints[1] endPoint2:element.point]];
                
                lastPoint = element.point;
                break;
                
            case NSClosePathBezierPathElement:
                lastPoint = CGPointZero;
                break;
        }
    }
    
    return bezierCurves;
}

+ (id) bezierCurveWithLineStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    return [[FBBezierCurve alloc] initWithLineStartPoint:startPoint endPoint:endPoint contour:nil];
}

+ (id) bezierCurveWithEndPoint1:(CGPoint)endPoint1 controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 endPoint2:(CGPoint)endPoint2
{
    return [[FBBezierCurve alloc] initWithEndPoint1:endPoint1 controlPoint1:controlPoint1 controlPoint2:controlPoint2 endPoint2:endPoint2 contour:nil];
}

+ (id) bezierCurveWithBezierCurveData:(FBBezierCurveData)data
{
    return [[FBBezierCurve alloc] initWithBezierCurveData:data];
}

- (id) initWithBezierCurveData:(FBBezierCurveData)data
{
    self = [super init];
    if ( self != nil ) {
        _data = data;
    }
    return self;
}

- (id) initWithEndPoint1:(CGPoint)endPoint1 controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 endPoint2:(CGPoint)endPoint2 contour:(FBBezierContour *)contour
{
    self = [super init];
    
    if ( self != nil ) {
        _data = FBBezierCurveDataMake(endPoint1, controlPoint1, controlPoint2, endPoint2, NO);
        _contour = contour; // no cyclical references
    }
    
    return self;
}

- (id) initWithLineStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint contour:(FBBezierContour *)contour
{
    self = [super init];
    
    if ( self != nil ) {
        // Convert the line into a bezier curve to keep our intersection algorithm general (i.e. only
        //  has to deal with curves, not lines). As long as the control points are colinear with the
        //  end points, it'll be a line. But for consistency sake, we put the control points inside
        //  the end points, 1/3 of the total distance away from their respective end point.
        CGFloat distance = FBDistanceBetweenPoints(startPoint, endPoint);
        CGPoint leftTangent = FBNormalizePoint(FBSubtractPoint(endPoint, startPoint));
        
        _data = FBBezierCurveDataMake(startPoint, FBAddPoint(startPoint, FBUnitScalePoint(leftTangent, distance / 3.0)), FBAddPoint(startPoint, FBUnitScalePoint(leftTangent, 2.0 * distance / 3.0)), endPoint, YES);
        _contour = contour; // no cyclical references
    }
    
    return self;
}


- (BOOL) isEqual:(id)object
{
    if ( ![object isKindOfClass:[FBBezierCurve class]] )
        return NO;
    
    FBBezierCurve *other = object;
    return FBBezierCurveDataIsEqual(_data, other->_data);
}

- (BOOL) doesHaveIntersectionsWithBezierCurve:(FBBezierCurve *)curve
{
    __block NSUInteger count = 0;
    [self intersectionsWithBezierCurve:curve overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
        ++count;
        *stop = YES; // Only need the one
    }];
    return count > 0;
}

- (void) intersectionsWithBezierCurve:(FBBezierCurve *)curve overlapRange:(FBBezierIntersectRange **)intersectRange withBlock:(FBCurveIntersectionBlock)block
{
    // For performance reasons, do a quick bounds check to see if these even might intersect
    if ( !FBLineBoundsMightOverlap(FBBezierCurveDataBoundingRect(&_data), FBBezierCurveDataBoundingRect(&curve->_data)) )
        return;
    
    if ( !FBLineBoundsMightOverlap(FBBezierCurveDataBounds(&_data), FBBezierCurveDataBounds(&curve->_data)) )
        return;

    FBRange usRange = FBRangeMake(0, 1);
    FBRange themRange = FBRangeMake(0, 1);
    BOOL stop = NO;
    FBBezierCurveDataIntersectionsWithBezierCurve(_data, curve.data, &usRange, &themRange, self, curve, intersectRange, 0, block, &stop);
}


- (FBBezierCurve *) subcurveWithRange:(FBRange)range
{
    return [FBBezierCurve bezierCurveWithBezierCurveData:FBBezierCurveDataSubcurveWithRange(_data, range)];
}

- (void) splitSubcurvesWithRange:(FBRange)range left:(FBBezierCurve **)leftCurve middle:(FBBezierCurve **)middleCurve right:(FBBezierCurve **)rightCurve
{
    // Return a bezier curve representing the parameter range specified. We do this by splitting
    //  twice: once on the minimum, the splitting the result of that on the maximum.
    
    // Start with the left side curve
    FBBezierCurveData remainingCurve = {};
    if ( range.minimum == 0.0 ) {
        remainingCurve = _data;
        if ( leftCurve != nil )
            *leftCurve = nil;
    } else {
        FBBezierCurveData leftCurveData = {};
        FBBezierCurveDataPointAtParameter(_data, range.minimum, &leftCurveData, &remainingCurve);
        if ( leftCurve != nil )
            *leftCurve = [FBBezierCurve bezierCurveWithBezierCurveData:leftCurveData];
    }

    // Special case  where we start at the end 
    if ( range.minimum == 1.0 ) {
        if ( middleCurve != nil )
            *middleCurve = [FBBezierCurve bezierCurveWithBezierCurveData:remainingCurve];
        if ( rightCurve != nil )
            *rightCurve = nil;
        return; // avoid the divide by zero below
    }
    
    // We need to adjust the maximum parameter to fit on the new curve before we split again
    CGFloat adjustedMaximum = (range.maximum - range.minimum) / (1.0 - range.minimum);
    FBBezierCurveData middleCurveData = {};
    FBBezierCurveData rightCurveData = {};
    FBBezierCurveDataPointAtParameter(remainingCurve, adjustedMaximum, &middleCurveData, &rightCurveData);
    if ( middleCurve != nil )
        *middleCurve = [FBBezierCurve bezierCurveWithBezierCurveData:middleCurveData];
    if ( rightCurve != nil )
        *rightCurve = [FBBezierCurve bezierCurveWithBezierCurveData:rightCurveData];
}

- (FBBezierCurve *) reversedCurve
{
    return [FBBezierCurve bezierCurveWithBezierCurveData:FBBezierCurveDataReversed(_data)];
}

- (CGPoint) pointAtParameter:(CGFloat)parameter leftBezierCurve:(FBBezierCurve **)leftBezierCurve rightBezierCurve:(FBBezierCurve **)rightBezierCurve
{
    FBBezierCurveData leftData = {};
    FBBezierCurveData rightData = {};
    CGPoint point = FBBezierCurveDataPointAtParameter(_data, parameter, &leftData, &rightData);
    if ( leftBezierCurve != nil ) {
        *leftBezierCurve = [FBBezierCurve bezierCurveWithBezierCurveData:leftData];
	}
    if ( rightBezierCurve != nil ) {
        *rightBezierCurve = [FBBezierCurve bezierCurveWithBezierCurveData:rightData];
	}
    return point;
}

- (CGFloat) refineParameter:(CGFloat)parameter forPoint:(CGPoint)point
{
    return FBBezierCurveDataRefineParameter(self.data, parameter, point);
}

- (CGFloat) length
{
    return FBBezierCurveDataGetLength(&_data);
}

- (CGFloat) lengthAtParameter:(CGFloat)parameter
{
    return FBBezierCurveDataGetLengthAtParameter(&_data, parameter);
}

- (BOOL) isPoint
{
    return FBBezierCurveDataIsPoint(&_data);
}

- (FBBezierCurveLocation) closestLocationToPoint:(CGPoint)point
{
    return FBBezierCurveDataClosestLocationToPoint(_data, point);
}

- (CGRect) bounds
{
    return FBBezierCurveDataBounds(&_data);
}

- (CGRect) boundingRect
{
    return FBBezierCurveDataBoundingRect(&_data);
}

- (CGPoint) pointFromRightOffset:(CGFloat)offset
{    
    CGFloat length = [self length];
    offset = MIN(offset, length);
    CGFloat time = 1.0 - (offset / length);
    return FBBezierCurveDataPointAtParameter(_data, time, nil, nil);
}

- (CGPoint) pointFromLeftOffset:(CGFloat)offset
{
    CGFloat length = [self length];
    offset = MIN(offset, length);
    CGFloat time = offset / length;
    return FBBezierCurveDataPointAtParameter(_data, time, nil, nil);
}

- (CGPoint) tangentFromRightOffset:(CGFloat)offset
{
    if ( _data.isStraightLine && !FBBezierCurveDataIsPoint(&_data) )
        return FBSubtractPoint(_data.endPoint1, _data.endPoint2);

    CGPoint returnValue = CGPointZero;
    if ( offset == 0.0 && !CGPointEqualToPoint(_data.controlPoint2, _data.endPoint2) )
        returnValue = FBSubtractPoint(_data.controlPoint2, _data.endPoint2);
    else {
        CGFloat length = FBBezierCurveDataGetLength(&_data);
        if ( offset == 0.0 )
            offset = MIN(1.0, length);
        CGFloat time = 1.0 - (offset / length);    
        FBBezierCurveData leftCurve = {};
        FBBezierCurveDataPointAtParameter(_data, time, &leftCurve, nil);
        returnValue = FBSubtractPoint(leftCurve.controlPoint2, leftCurve.endPoint2);
    }
        
    return returnValue;
}

- (CGPoint) tangentFromLeftOffset:(CGFloat)offset
{
    if ( _data.isStraightLine && !FBBezierCurveDataIsPoint(&_data) )
        return FBSubtractPoint(_data.endPoint2, _data.endPoint1);

    CGPoint returnValue = CGPointZero;
    if ( offset == 0.0 && !CGPointEqualToPoint(_data.controlPoint1, _data.endPoint1) )
        returnValue = FBSubtractPoint(_data.controlPoint1, _data.endPoint1);
    else {
        CGFloat length = FBBezierCurveDataGetLength(&_data);
        if ( offset == 0.0 )
            offset = MIN(1.0, length);
        CGFloat time = offset / length;
        FBBezierCurveData rightCurve = {};
        FBBezierCurveDataPointAtParameter(_data, time, nil, &rightCurve);
        returnValue = FBSubtractPoint(rightCurve.controlPoint1, rightCurve.endPoint1);
    }
        
    return returnValue;
}

- (NSBezierPath *) bezierPath
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:self.endPoint1];
    [path curveToPoint:self.endPoint2 controlPoint1:self.controlPoint1 controlPoint2:self.controlPoint2];
    return path;
}

- (FBBezierCurve *) clone
{
    return [FBBezierCurve bezierCurveWithBezierCurveData:_data];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ (%.18f, %.18f)-[%.18f, %.18f] curve to [%.18f, %.18f]-(%.18f, %.18f)>", 
            NSStringFromClass([self class]), 
            _data.endPoint1.x, _data.endPoint1.y, _data.controlPoint1.x, _data.controlPoint1.y,
            _data.controlPoint2.x, _data.controlPoint2.y, _data.endPoint2.x, _data.endPoint2.y];
}

@end
