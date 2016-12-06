//
//  FBContourOverlap.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 11/7/12.
//  Copyright (c) 2012 Fortunate Bear, LLC. All rights reserved.
//

#import "FBContourOverlap.h"
#import "FBBezierIntersectRange.h"
#import "FBBezierCurve.h"
#import "FBBezierCurve+Edge.h"
#import "FBBezierContour.h"
#import "FBEdgeCrossing.h"
#import "FBDebug.h"

@interface FBEdgeOverlap ()

+ (id) overlapWithRange:(FBBezierIntersectRange *)range edge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2;
- (id) initWithRange:(FBBezierIntersectRange *)range edge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2;

@property (readonly) FBBezierCurve *edge1;
@property (readonly) FBBezierCurve *edge2;

- (BOOL) fitsBefore:(FBEdgeOverlap *)nextOverlap;
- (BOOL) fitsAfter:(FBEdgeOverlap *)previousOverlap;

- (void) addMiddleCrossing;

- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge startExtends:(BOOL)extendsBeforeStart endExtends:(BOOL)extendsAfterEnd;

@end

@interface FBEdgeOverlapRun ()

+ (id) overlapRun;

- (BOOL) insertOverlap:(FBEdgeOverlap *)overlap;

- (BOOL) isComplete;

@property (weak, readonly) FBBezierContour *contour1;
@property (weak, readonly) FBBezierContour *contour2;

- (BOOL) doesContainCrossing:(FBEdgeCrossing *)crossing;
- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge;

@end

@interface FBContourOverlap ()

@property (weak, readonly) NSMutableArray * runs_;

@end

static const CGFloat FBOverlapThreshold = 1e-2;

static CGFloat FBComputeEdge1Tangents(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint edge1Tangents[2])
{
    // edge1Tangents are firstOverlap.range1.minimum going to previous and lastOverlap.range1.maximum going to next
    CGFloat firstLength = 0.0;
    CGFloat lastLength = 0.0;
    if ( firstOverlap.range.isAtStartOfCurve1 ) {
        FBBezierCurve *otherEdge1 = firstOverlap.edge1.previousNonpoint;
        edge1Tangents[0] = [otherEdge1 tangentFromRightOffset:offset];
        firstLength = [otherEdge1 length];
    } else {
        edge1Tangents[0] = [firstOverlap.range.curve1LeftBezier tangentFromRightOffset:offset];
        firstLength = [firstOverlap.range.curve1LeftBezier length];
    }
    if ( lastOverlap.range.isAtStopOfCurve1 ) {
        FBBezierCurve *otherEdge1 = lastOverlap.edge1.nextNonpoint;
        edge1Tangents[1] = [otherEdge1 tangentFromLeftOffset:offset];
        lastLength = [otherEdge1 length];
    } else {
        edge1Tangents[1] = [lastOverlap.range.curve1RightBezier tangentFromLeftOffset:offset];
        lastLength = [lastOverlap.range.curve1RightBezier length];
    }
    return MIN(firstLength, lastLength);
}

static CGFloat FBComputeEdge2Tangents(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint edge2Tangents[2])
{
    // edge2Tangents are firstOverlap.range2.minimum going to previous and lastOverlap.range2.maximum going to next
    //  unless reversed, then
    // edge2Tangents are firstOverlap.range2.maximum going to next and lastOverlap.range2.minimum going to previous
    CGFloat firstLength = 0.0;
    CGFloat lastLength = 0.0;
    if ( !firstOverlap.range.reversed ) {
        if ( firstOverlap.range.isAtStartOfCurve2 ) {
            FBBezierCurve *otherEdge2 = firstOverlap.edge2.previousNonpoint;
            edge2Tangents[0] = [otherEdge2 tangentFromRightOffset:offset];
            firstLength = [otherEdge2 length];
        } else {
            edge2Tangents[0] = [firstOverlap.range.curve2LeftBezier tangentFromRightOffset:offset];
            firstLength = [firstOverlap.range.curve2LeftBezier length];
        }
        if ( lastOverlap.range.isAtStopOfCurve2 ) {
            FBBezierCurve *otherEdge2 = lastOverlap.edge2.nextNonpoint;
            edge2Tangents[1] = [otherEdge2 tangentFromLeftOffset:offset];
            lastLength = [otherEdge2 length];
        } else {
            edge2Tangents[1] = [lastOverlap.range.curve2RightBezier tangentFromLeftOffset:offset];
            lastLength = [lastOverlap.range.curve2RightBezier length];
        }
    } else {
        if ( firstOverlap.range.isAtStopOfCurve2 ) {
            FBBezierCurve *otherEdge2 = firstOverlap.edge2.nextNonpoint;
            edge2Tangents[0] = [otherEdge2 tangentFromLeftOffset:offset];
            firstLength = [otherEdge2 length];
        } else {
            edge2Tangents[0] = [firstOverlap.range.curve2RightBezier tangentFromLeftOffset:offset];
            firstLength = [firstOverlap.range.curve2RightBezier length];
        }
        if ( lastOverlap.range.isAtStartOfCurve2 ) {
            FBBezierCurve *otherEdge2 = lastOverlap.edge2.previousNonpoint;
            edge2Tangents[1] = [otherEdge2 tangentFromRightOffset:offset];
            lastLength = [otherEdge2 length];
        } else {
            edge2Tangents[1] = [lastOverlap.range.curve2LeftBezier tangentFromRightOffset:offset];
            lastLength = [lastOverlap.range.curve2LeftBezier length];
        }
    }
    return MIN(firstLength, lastLength);
}

static void FBComputeEdge1TestPoints(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint testPoints[2])
{
    // edge1Tangents are firstOverlap.range1.minimum going to previous and lastOverlap.range1.maximum going to next
    if ( firstOverlap.range.isAtStartOfCurve1 ) {
        FBBezierCurve *otherEdge1 = firstOverlap.edge1.previousNonpoint;
        testPoints[0] = [otherEdge1 pointFromRightOffset:offset];
    } else
        testPoints[0] = [firstOverlap.range.curve1LeftBezier pointFromRightOffset:offset];
    if ( lastOverlap.range.isAtStopOfCurve1 ) {
        FBBezierCurve *otherEdge1 = lastOverlap.edge1.nextNonpoint;
        testPoints[1] = [otherEdge1 pointFromLeftOffset:offset];
    } else
        testPoints[1] = [lastOverlap.range.curve1RightBezier pointFromLeftOffset:offset];
}

@implementation FBContourOverlap


+ (id) contourOverlap
{
    return [[FBContourOverlap alloc] init];
}


- (NSMutableArray *) runs_
{
    if ( _runs == nil )
        _runs = [[NSMutableArray alloc] initWithCapacity:4];
    
    return _runs;
}

- (void) addOverlap:(FBBezierIntersectRange *)range forEdge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2
{
    FBEdgeOverlap *overlap = [FBEdgeOverlap overlapWithRange:range edge1:edge1 edge2:edge2];
    BOOL createNewRun = NO;
    if ( _runs == nil || _runs.count == 0 ) {
        createNewRun = YES;
    } else if ( _runs.count == 1 ) {
        BOOL inserted = [_runs.lastObject insertOverlap:overlap];
        createNewRun = !inserted;
    } else {
        BOOL inserted = [_runs.lastObject insertOverlap:overlap];
        if ( !inserted )
            inserted = [_runs[0] insertOverlap:overlap];
        createNewRun = !inserted;
    }
    if ( createNewRun ) {
        FBEdgeOverlapRun *run = [FBEdgeOverlapRun overlapRun];
        [run insertOverlap:overlap];
        [self.runs_ addObject:run];
    }
}

- (BOOL) doesContainCrossing:(FBEdgeCrossing *)crossing
{
    if ( _runs == nil )
        return NO;
    
    for (FBEdgeOverlapRun *run in _runs) {
        if ( [run doesContainCrossing:crossing] )
            return YES;
    }
    return NO;
}

- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge
{
    if ( _runs == nil )
        return NO;

    for (FBEdgeOverlapRun *run in _runs) {
        if ( [run doesContainParameter:parameter onEdge:edge] )
            return YES;
    }
    return NO;    
}

- (void) runsWithBlock:(void (^)(FBEdgeOverlapRun *run, BOOL *stop))block
{
    if ( _runs == nil )
        return;
    
    BOOL stop = NO;
    for (FBEdgeOverlapRun *run in _runs) {
        block(run, &stop);
        if ( stop )
            break;
    }
}

- (void) reset
{
    if ( _runs == nil )
        return;
    
    [_runs removeAllObjects];
}

- (BOOL) isComplete
{
    if ( _runs == nil )
        return NO;

    // To be complete, we should have exactly one run that wraps around
    if ( _runs.count != 1 )
        return NO;
    
    return [_runs[0] isComplete];
}

- (BOOL) isEmpty
{
    return _runs == nil || _runs.count == 0;
}

- (FBBezierContour *) contour1
{
    if ( _runs == nil || _runs.count == 0 )
        return nil;

    FBEdgeOverlapRun *run = _runs[0];
    return run.contour1;
}

- (FBBezierContour *) contour2
{
    if ( _runs == nil || _runs.count == 0 )
        return nil;

    FBEdgeOverlapRun *run = _runs[0];
    return run.contour2;
}

- (BOOL) isBetweenContour:(FBBezierContour *)contour1 andContour:(FBBezierContour *)contour2
{
    FBBezierContour *myContour1 = self.contour1;
    FBBezierContour *myContour2 = self.contour2;
    return (contour1 == myContour1 && contour2 == myContour2) || (contour1 == myContour2 && contour2 == myContour1);
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: runs = %@>", 
            NSStringFromClass([self class]), FBArrayDescription(_runs)];
}

@end

@implementation FBEdgeOverlapRun

@synthesize overlaps=_overlaps;

+ (id) overlapRun
{
    return [[FBEdgeOverlapRun alloc] init];
}

- (id) init
{
    self = [super init];
    if ( self != nil ) {
        _overlaps = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}


- (BOOL) insertOverlap:(FBEdgeOverlap *)overlap
{
    if ( _overlaps.count == 0 ) {
        // The first one always works
        [_overlaps addObject:overlap];
        return YES;
    }
    
    // Check to see if overlap fits after our last overlap
    FBEdgeOverlap *lastOverlap = _overlaps.lastObject;
    if ( [lastOverlap fitsBefore:overlap] ) {
        [_overlaps addObject:overlap];
        return YES;
    }
    // Check to see if overlap fits before our first overlap
    FBEdgeOverlap *firstOverlap = _overlaps.firstObject;
    if ( [firstOverlap fitsAfter:overlap] ) {
        [_overlaps insertObject:overlap atIndex:0];
        return YES;
    }
    return NO;
}

- (BOOL) isComplete
{
    // To be complete, we should wrap around
    if ( _overlaps.count == 0 )
        return NO;
    
    FBEdgeOverlap *lastOverlap = _overlaps.lastObject;
    FBEdgeOverlap *firstOverlap = _overlaps.firstObject;
    return [lastOverlap fitsBefore:firstOverlap];
}

- (BOOL) doesContainCrossing:(FBEdgeCrossing *)crossing
{
    return [self doesContainParameter:crossing.parameter onEdge:crossing.edge];
}

- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge
{
    if ( _overlaps.count == 0 )
        return NO;
    
    // Find the FBEdgeOverlap that contains the crossing (if it exists)
    FBEdgeOverlap *containingOverlap = nil;
    for (FBEdgeOverlap *overlap in _overlaps) {
        if ( overlap.edge1 == edge || overlap.edge2 == edge ) {
            containingOverlap = overlap;
            break;
        }
    }
    
    // The edge it's attached to isn't here
    if ( containingOverlap == nil )
        return NO;
    
    
    FBEdgeOverlap *lastOverlap = _overlaps.lastObject;
    FBEdgeOverlap *firstOverlap = _overlaps.firstObject;
    
    BOOL atTheStart = containingOverlap == firstOverlap;
    BOOL extendsBeforeStart = !atTheStart || (atTheStart && [lastOverlap fitsBefore:firstOverlap]);
    
    BOOL atTheEnd = containingOverlap == lastOverlap;
    BOOL extendsAfterEnd = !atTheEnd || (atTheEnd && [firstOverlap fitsAfter:lastOverlap]);
    
    return [containingOverlap doesContainParameter:parameter onEdge:edge startExtends:extendsBeforeStart endExtends:extendsAfterEnd];
}

- (BOOL) isCrossing
{
    // The intersection happens at the end of one of the edges, meaning we'll have to look at the next
    //  edge in sequence to see if it crosses or not. We'll do that by computing the four tangents at the exact
    //  point the intersection takes place. We'll compute the polar angle for each of the tangents. If the
    //  angles of self split the angles of edge2 (i.e. they alternate when sorted), then the edges cross. If
    //  any of the angles are equal or if the angles group up, then the edges don't cross.

    // Calculate the four tangents: The two tangents moving away from the intersection point on self, the two tangents
    //  moving away from the intersection point on edge2.

    FBEdgeOverlap *firstOverlap = _overlaps.firstObject;
    FBEdgeOverlap *lastOverlap = _overlaps.lastObject;

    NSPoint edge1Tangents[] = { NSZeroPoint, NSZeroPoint };
    NSPoint edge2Tangents[] = { NSZeroPoint, NSZeroPoint };
    CGFloat offset = 0.0;
    CGFloat maxOffset = 0.0;

    do {
        CGFloat length1 = FBComputeEdge1Tangents(firstOverlap, lastOverlap, offset, edge1Tangents);
        CGFloat length2 = FBComputeEdge2Tangents(firstOverlap, lastOverlap, offset, edge2Tangents);
        maxOffset = MIN(length1, length2);
        
        offset += 1.0;
    } while ( FBAreTangentsAmbigious(edge1Tangents, edge2Tangents) && offset < maxOffset);
    
    if ( FBTangentsCross(edge1Tangents, edge2Tangents) )
        return YES;
    
    // Tangents work, mostly, for overlaps. If we get a yes, it's solid. If we get a no, it might still
    //  be a crossing. Only way to tell now is to an actual point test
    NSPoint testPoints[2] = {};
    FBComputeEdge1TestPoints(firstOverlap, lastOverlap, 1.0, testPoints);
    FBBezierContour *contour2 = firstOverlap.edge2.contour;
    BOOL testPoint1Inside = [contour2 containsPoint:testPoints[0]];
    BOOL testPoint2Inside = [contour2 containsPoint:testPoints[1]];
    return testPoint1Inside != testPoint2Inside;
}

- (void) addCrossings
{
    // Add crossings to both graphs for this intersection/overlap. Pick the middle point and use that
    if ( _overlaps.count == 0 )
        return;
    
    FBEdgeOverlap *middleOverlap = _overlaps[_overlaps.count / 2];
    [middleOverlap addMiddleCrossing];
}

- (FBBezierContour *) contour1
{
    if ( _overlaps.count == 0 )
        return nil;
    
    FBEdgeOverlap *overlap = _overlaps.firstObject;
    return overlap.edge1.contour;
}

- (FBBezierContour *) contour2
{
    if ( _overlaps.count == 0 )
        return nil;
    
    FBEdgeOverlap *overlap = _overlaps.firstObject;
    return overlap.edge2.contour;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: overlaps = %@>", 
            NSStringFromClass([self class]), FBArrayDescription(_overlaps)];
}

@end

@implementation FBEdgeOverlap

@synthesize edge1=_edge1;
@synthesize edge2=_edge2;
@synthesize range=_range;

+ (id) overlapWithRange:(FBBezierIntersectRange *)range edge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2
{
    return [[FBEdgeOverlap alloc] initWithRange:range edge1:edge1 edge2:edge2];
}

- (id) initWithRange:(FBBezierIntersectRange *)range edge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2
{
    self = [super init];
    if ( self != nil ) {
        _edge1 = edge1;
        _edge2 = edge2;
        _range = range;
    }
    return self;
}


- (BOOL) fitsBefore:(FBEdgeOverlap *)nextOverlap
{
    if ( FBAreValuesCloseWithOptions(_range.parameterRange1.maximum, 1.0, FBOverlapThreshold) ) {
        // nextOverlap should start at 0 of the next edge
        FBBezierCurve *nextEdge = _edge1.next;
        return nextOverlap.edge1 == nextEdge && FBAreValuesCloseWithOptions(nextOverlap.range.parameterRange1.minimum, 0.0, FBOverlapThreshold);
    }
    
    // nextOverlap should start at about maximum on the same edge
    return nextOverlap.edge1 == _edge1 && FBAreValuesCloseWithOptions(nextOverlap.range.parameterRange1.minimum, _range.parameterRange1.maximum, FBOverlapThreshold);
}

- (BOOL) fitsAfter:(FBEdgeOverlap *)previousOverlap
{
    if ( FBAreValuesCloseWithOptions(_range.parameterRange1.minimum, 0.0, FBOverlapThreshold) ) {
        // previousOverlap should end at 1 of the previous edge
        FBBezierCurve *previousEdge = _edge1.previous;
        return previousOverlap.edge1 == previousEdge && FBAreValuesCloseWithOptions(previousOverlap.range.parameterRange1.maximum, 1.0, FBOverlapThreshold);
    }
    
    // previousOverlap should end at about the minimum on the same edge
    return previousOverlap.edge1 == _edge1 && FBAreValuesCloseWithOptions(previousOverlap.range.parameterRange1.maximum, _range.parameterRange1.minimum, FBOverlapThreshold);
}

- (void) addMiddleCrossing
{
    FBBezierIntersection *intersection = _range.middleIntersection;
    FBEdgeCrossing *ourCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
    FBEdgeCrossing *theirCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
    ourCrossing.counterpart = theirCrossing;
    theirCrossing.counterpart = ourCrossing;
    ourCrossing.fromCrossingOverlap = YES;
    theirCrossing.fromCrossingOverlap = YES;
    [_edge1 addCrossing:ourCrossing];
    [_edge2 addCrossing:theirCrossing];
}

- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge startExtends:(BOOL)extendsBeforeStart endExtends:(BOOL)extendsAfterEnd
{
    // By the time this is called, we know the crossing is on one of our edges.
    if ( extendsBeforeStart && extendsAfterEnd )
        return YES; // The crossing is on the edge somewhere, and the overlap extens past this edge in both directions, so its safe to say the crossing is contained
    
    FBRange parameterRange = {};
    if ( edge == _edge1 )
        parameterRange = _range.parameterRange1;
    else
        parameterRange = _range.parameterRange2;
    
    BOOL inLeftSide = extendsBeforeStart ? parameter >= 0.0 : parameter > parameterRange.minimum;
    BOOL inRightSide = extendsAfterEnd ? parameter <= 1.0 : parameter < parameterRange.maximum;
    return inLeftSide && inRightSide;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: edge1 = %@, edge2 = %@, range = %@>", 
            NSStringFromClass([self class]), self.edge1, self.edge2, self.range];
}

@end
