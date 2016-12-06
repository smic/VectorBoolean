//
//  FBBezierCurve+Edge.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 7/3/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierCurve+Edge.h"
#import "FBEdgeCrossing.h"
#import "FBBezierContour.h"
#import "FBBezierIntersection.h"
#import "FBBezierIntersectRange.h"
#import "FBBezierCurve.h"
#import "FBGeometry.h"
#import "FBDebug.h"

static void FBFindEdge1TangentCurves(FBBezierCurve *edge, FBBezierIntersection *intersection, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
{
    if ( intersection.isAtStartOfCurve1 ) {
        *leftCurve = edge.previousNonpoint;
        *rightCurve = edge;
    } else if ( intersection.isAtStopOfCurve1 ) {
        *leftCurve = edge;
        *rightCurve = edge.nextNonpoint;
    } else {
        *leftCurve = intersection.curve1LeftBezier;
        *rightCurve = intersection.curve1RightBezier;
    }
}

static void FBFindEdge2TangentCurves(FBBezierCurve *edge, FBBezierIntersection *intersection, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
{
    if ( intersection.isAtStartOfCurve2 ) {
        *leftCurve = edge.previousNonpoint;
        *rightCurve = edge;
    } else if ( intersection.isAtStopOfCurve2 ) {
        *leftCurve = edge;
        *rightCurve = edge.nextNonpoint;
    } else {
        *leftCurve = intersection.curve2LeftBezier;
        *rightCurve = intersection.curve2RightBezier;
    }
}

static void FBComputeEdgeTangents(FBBezierCurve* leftCurve, FBBezierCurve *rightCurve, CGFloat offset, NSPoint edgeTangents[2])
{
    edgeTangents[0] = [leftCurve tangentFromRightOffset:offset];
    edgeTangents[1] = [rightCurve tangentFromLeftOffset:offset];
}


static void FBComputeEdge1RangeTangentCurves(FBBezierCurve *edge, FBBezierIntersectRange *intersectRange, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
{
    // edge1Tangents are firstOverlap.range1.minimum going to previous and lastOverlap.range1.maximum going to next
    if ( intersectRange.isAtStartOfCurve1 )
        *leftCurve = edge.previousNonpoint;
    else
        *leftCurve = intersectRange.curve1LeftBezier;
    if ( intersectRange.isAtStopOfCurve1 )
        *rightCurve = edge.nextNonpoint;
    else
        *rightCurve = intersectRange.curve1RightBezier;
}

static void FBComputeEdge2RangeTangentCurves(FBBezierCurve *edge, FBBezierIntersectRange *intersectRange, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
{
    // edge2Tangents are firstOverlap.range2.minimum going to previous and lastOverlap.range2.maximum going to next
    if ( intersectRange.isAtStartOfCurve2 )
        *leftCurve = edge.previousNonpoint;
    else
        *leftCurve = intersectRange.curve2LeftBezier;
    if ( intersectRange.isAtStopOfCurve2 ) {
        *rightCurve = edge.nextNonpoint;
    } else
        *rightCurve = intersectRange.curve2RightBezier;
}

@interface FBBezierCurve (EdgePrivate)

- (void) sortCrossings;

@property (readonly) NSMutableArray *crossings_;

@end

@implementation FBBezierCurve (Edge)

- (NSUInteger) index
{
    return _index;
}

- (void) setIndex:(NSUInteger)index
{
    _index = index;
}

- (BOOL) isStartShared
{
    return _startShared;
}

- (void) setStartShared:(BOOL)startShared
{
    _startShared = startShared;
}

- (FBBezierContour *) contour
{
    return _contour;
}

- (void) setContour:(FBBezierContour *)contour
{
    _contour = contour; // no cycles
}

- (void) addCrossing:(FBEdgeCrossing *)crossing
{
    // Make sure the crossing can make it back to us, and keep all the crossings sorted
    crossing.edge = self;
    [self.crossings_ addObject:crossing];
    [self sortCrossings];
}

- (void) removeCrossing:(FBEdgeCrossing *)crossing
{
    // Keep the crossings sorted
    crossing.edge = nil;
    [_crossings removeObject:crossing];
    [self sortCrossings];
}

- (void) removeAllCrossings
{
    [_crossings removeAllObjects];
}

- (FBBezierCurve *)next
{
    if ( _contour == nil )
        return self;
    
    if ( _index >= (self.contour.edges.count - 1) )
        return self.contour.edges.firstObject;
    
    return self.contour.edges[_index + 1];
}

- (FBBezierCurve *)previous
{
    if ( _contour == nil )
        return self;
    
    if ( _index == 0 )
        return self.contour.edges.lastObject;
    
    return self.contour.edges[_index - 1];
}

- (FBBezierCurve *) nextNonpoint
{
    FBBezierCurve *edge = self.next;
    while ( edge.isPoint )
        edge = edge.next;
    return edge;
}

- (FBBezierCurve *) previousNonpoint
{
    FBBezierCurve *edge = self.previous;
    while ( edge.isPoint )
        edge = edge.previous;
    return edge;
}

- (BOOL) hasCrossings
{
    return _crossings != nil && _crossings.count > 0;
}

- (void) crossingsWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block
{
    if ( _crossings == nil )
        return;
    
    BOOL stop = NO;
    for (FBEdgeCrossing *crossing in _crossings) {
        block(crossing, &stop);
        if ( stop )
            break;
    }
}

- (void) crossingsCopyWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block
{
    if ( _crossings == nil )
        return;
    
    BOOL stop = NO;
    NSArray *crossingsCopy = [_crossings copy];
    for (FBEdgeCrossing *crossing in crossingsCopy) {
        block(crossing, &stop);
        if ( stop )
            break;
    }
}

- (FBEdgeCrossing *) nextCrossing:(FBEdgeCrossing *)crossing
{
    if ( _crossings == nil || crossing.index >= (_crossings.count - 1) )
        return nil;
    
    return _crossings[crossing.index + 1];
}

- (FBEdgeCrossing *) previousCrossing:(FBEdgeCrossing *)crossing
{
    if ( _crossings == nil || crossing.index == 0 )
        return nil;
    
    return _crossings[crossing.index - 1];
}

- (void) intersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block
{
    [self crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
        if ( crossing.isSelfCrossing )
            return; // Right now skip over self intersecting crossings
        FBBezierCurve *intersectingEdge = crossing.counterpart.edge;
        block(intersectingEdge);
    }];
}

- (void) selfIntersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block
{
    [self crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
        if ( !crossing.isSelfCrossing )
            return; // Only want the self intersecting crossings
        FBBezierCurve *intersectingEdge = crossing.counterpart.edge;
        block(intersectingEdge);
    }];
}

- (FBEdgeCrossing *) firstCrossing
{
    if ( _crossings == nil || _crossings.count == 0 )
        return nil;
    return _crossings.firstObject;
}

- (FBEdgeCrossing *) lastCrossing
{
    if ( _crossings == nil || _crossings.count == 0 )
        return nil;
    return _crossings.lastObject;
}

- (FBEdgeCrossing *) firstNonselfCrossing
{
    FBEdgeCrossing *first = self.firstCrossing;
    while ( first != nil && first.isSelfCrossing )
        first = first.next;
    return first;
}

- (FBEdgeCrossing *) lastNonselfCrossing
{
    FBEdgeCrossing *last = self.lastCrossing;
    while ( last != nil && last.isSelfCrossing )
        last = last.previous;
    return last;
}

- (BOOL) hasNonselfCrossings
{
    BOOL hasNonself = NO;
    for (FBEdgeCrossing *crossing in _crossings) {
        if ( !crossing.isSelfCrossing ) {
            hasNonself = YES;
            break;
        }
    }
    return hasNonself;
}

- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersection:(FBBezierIntersection *)intersection
{
    // If it's tangent, then it doesn't cross
    if ( intersection.isTangent )
        return NO;
    // If the intersect happens in the middle of both curves, then it definitely crosses, so we can just return yes. Most
    //  intersections will fall into this category.
    if ( !intersection.isAtEndPointOfCurve )
        return YES;
    
    // The intersection happens at the end of one of the edges, meaning we'll have to look at the next
    //  edge in sequence to see if it crosses or not. We'll do that by computing the four tangents at the exact
    //  point the intersection takes place. We'll compute the polar angle for each of the tangents. If the
    //  angles of self split the angles of edge2 (i.e. they alternate when sorted), then the edges cross. If
    //  any of the angles are equal or if the angles group up, then the edges don't cross.
    
    // Calculate the four tangents: The two tangents moving away from the intersection point on self, the two tangents
    //  moving away from the intersection point on edge2.
    NSPoint edge1Tangents[] = { NSZeroPoint, NSZeroPoint };
    NSPoint edge2Tangents[] = { NSZeroPoint, NSZeroPoint };
    CGFloat offset = 0.0;
    
    FBBezierCurve *edge1LeftCurve = nil;
    FBBezierCurve *edge1RightCurve = nil;
    FBFindEdge1TangentCurves(self, intersection, &edge1LeftCurve, &edge1RightCurve);
    CGFloat edge1Length = MIN([edge1LeftCurve length], [edge1RightCurve length]);
    
    FBBezierCurve *edge2LeftCurve = nil;
    FBBezierCurve *edge2RightCurve = nil;
    FBFindEdge2TangentCurves(edge2, intersection, &edge2LeftCurve, &edge2RightCurve);
    CGFloat edge2Length = MIN([edge2LeftCurve length], [edge2RightCurve length]);
    
    CGFloat maxOffset = MIN(edge1Length, edge2Length);
    
    do {
        FBComputeEdgeTangents(edge1LeftCurve, edge1RightCurve, offset, edge1Tangents);
        FBComputeEdgeTangents(edge2LeftCurve, edge2RightCurve, offset, edge2Tangents);
        
        offset += 1.0;
    } while ( FBAreTangentsAmbigious(edge1Tangents, edge2Tangents) && offset < maxOffset );
    
    return FBTangentsCross(edge1Tangents, edge2Tangents);
}

- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersectRange:(FBBezierIntersectRange *)intersectRange
{
    // Calculate the four tangents: The two tangents moving away from the intersection point on self, the two tangents
    //  moving away from the intersection point on edge2.
    NSPoint edge1Tangents[] = { NSZeroPoint, NSZeroPoint };
    NSPoint edge2Tangents[] = { NSZeroPoint, NSZeroPoint };
    CGFloat offset = 0.0;
    
    FBBezierCurve *edge1LeftCurve = nil;
    FBBezierCurve *edge1RightCurve = nil;
    FBComputeEdge1RangeTangentCurves(self, intersectRange, &edge1LeftCurve, &edge1RightCurve);
    CGFloat edge1Length = MIN([edge1LeftCurve length], [edge1RightCurve length]);
    
    FBBezierCurve *edge2LeftCurve = nil;
    FBBezierCurve *edge2RightCurve = nil;
    FBComputeEdge2RangeTangentCurves(edge2, intersectRange, &edge2LeftCurve, &edge2RightCurve);
    CGFloat edge2Length = MIN([edge2LeftCurve length], [edge2RightCurve length]);
    
    CGFloat maxOffset = MIN(edge1Length, edge2Length);
    
    do {
        FBComputeEdgeTangents(edge1LeftCurve, edge1RightCurve, offset, edge1Tangents);
        FBComputeEdgeTangents(edge2LeftCurve, edge2RightCurve, offset, edge2Tangents);
        
        offset += 1.0;
    } while ( FBAreTangentsAmbigious(edge1Tangents, edge2Tangents) && offset < maxOffset );
    
    return FBTangentsCross(edge1Tangents, edge2Tangents);
}

@end

@implementation FBBezierCurve (EdgePrivate)

- (NSMutableArray *) crossings_
{
    if ( _crossings != nil )
        return _crossings;
    _crossings = [[NSMutableArray alloc] initWithCapacity:4];
    return _crossings;
}

- (void) sortCrossings
{
    if ( _crossings == nil )
        return;
    
    // Sort by the "order" of the crossing, then assign indices so next and previous work correctly.
    [_crossings sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        FBEdgeCrossing *crossing1 = obj1;
        FBEdgeCrossing *crossing2 = obj2;
        if ( crossing1.order < crossing2.order )
            return NSOrderedAscending;
        else if ( crossing1.order > crossing2.order )
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    NSUInteger index = 0;
    for (FBEdgeCrossing *crossing in _crossings)
        crossing.index = index++;
}

@end
