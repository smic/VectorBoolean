//
//  FBBezierCurve+Edge.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 7/3/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierCurve.h"

@class FBEdgeCrossing, FBBezierIntersection, FBBezierIntersectRange;

@interface FBBezierCurve (Edge)

@property (assign) FBBezierContour *contour;
@property NSUInteger index;

// An easy way to iterate all the edges. Wraps around.
@property (readonly) FBBezierCurve *next;
@property (readonly) FBBezierCurve *previous;
@property (readonly) FBBezierCurve *nextNonpoint;
@property (readonly) FBBezierCurve *previousNonpoint;

@property (readonly) FBEdgeCrossing *firstCrossing;
@property (readonly) FBEdgeCrossing *lastCrossing;

@property (readonly) BOOL hasCrossings;

@property (readonly) FBEdgeCrossing *firstNonselfCrossing;
@property (readonly) FBEdgeCrossing *lastNonselfCrossing;

@property (readonly) BOOL hasNonselfCrossings;

- (void) crossingsWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block;
- (void) crossingsCopyWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block;

- (FBEdgeCrossing *) nextCrossing:(FBEdgeCrossing *)crossing;
- (FBEdgeCrossing *) previousCrossing:(FBEdgeCrossing *)crossing;


- (void) intersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block;
- (void) selfIntersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block;

// Store if there are any intersections at either end of this edge.
@property (getter = isStartShared) BOOL startShared;

- (void) addCrossing:(FBEdgeCrossing *)crossing;
- (void) removeCrossing:(FBEdgeCrossing *)crossing;
- (void) removeAllCrossings;

- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersection:(FBBezierIntersection *)intersection;
- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersectRange:(FBBezierIntersectRange *)intersectRange;

@end
