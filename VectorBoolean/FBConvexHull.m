//
//  FBConvexHull.m
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import "FBConvexHull.h"
#import "FBGeometry.h"
#import "FBBezierCurveHelper.h"

#pragma mark Convex Hull

//////////////////////////////////////////////////////////////////////////////////
// Convex Hull functions

static inline BOOL FBConvexHullDoPointsTurnWrongDirection(NSPoint point1, NSPoint point2, NSPoint point3)
{
    CGFloat area = CounterClockwiseTurn(point1, point2, point3);
    return FBAreValuesClose(area, 0.0) || area < 0.0;
}

void FBConvexHullBuildFromPoints(NSPoint points[4], NSPoint *results, NSUInteger *outLength)
{
    // Compute the convex hull for this bezier curve. The convex hull is made up of the end and control points.
    //  The hard part is determine the order they go in, and if any are inside or colinear with the convex hull.
    
    // Uses the Monotone chain algorithm:
    //  http://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
    
    // Start with all the end and control points in any order.
    NSUInteger numberOfPoints = 4;
    
    // Sort points ascending x, if equal compare y
    //  Bubble sort, which should be ok with a max of 4 elements, and the fact that our one current use case
    //  already has them in ascending X order (i.e. should be just comparisons to verify)
    NSUInteger sortLength = numberOfPoints;
    do {
        NSUInteger newSortLength = 0;
        for (NSUInteger i = 1; i < sortLength; i++) {
            if ( points[i - 1].x > points[i].x || (FBAreValuesClose(points[i - 1].x, points[i].x) && points[i - 1].y > points[i].y) ) {
                NSPoint tempPoint = points[i];
                points[i] = points[i - 1];
                points[i - 1] = tempPoint;
                newSortLength = i;
            }
        }
        sortLength = newSortLength;
    } while ( sortLength > 0 );
    
    
    // Create the results
    NSUInteger filledInIndex = 0;
    
    // Build lower hull
    for (NSUInteger i = 0; i < numberOfPoints; i++) {
        while ( filledInIndex >= 2 && FBConvexHullDoPointsTurnWrongDirection(results[filledInIndex - 2], results[filledInIndex - 1], points[i]) )
            --filledInIndex;
        results[filledInIndex] = points[i];
        ++filledInIndex;
    }
    
    // Build upper hull
    for (NSInteger i = numberOfPoints - 2, thresholdIndex = filledInIndex + 1; i >= 0; i--) {
        while ( filledInIndex >= thresholdIndex && FBConvexHullDoPointsTurnWrongDirection(results[filledInIndex - 2], results[filledInIndex - 1], points[i]) )
            --filledInIndex;
        results[filledInIndex] = points[i];
        ++filledInIndex;
    }
    
    *outLength = filledInIndex - 1;
}
