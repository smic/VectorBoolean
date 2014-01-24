//
//  FBBezierContour.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierContour.h"
#import "FBBezierCurve.h"
#import "FBBezierCurve+Edge.h"
#import "FBEdgeCrossing.h"
#import "FBContourOverlap.h"
#import "FBDebug.h"
#import "FBGeometry.h"
#import "FBBezierIntersection.h"
#import "NSBezierPath+Utilities.h"
#import "FBCurveLocation.h"
#import "FBBezierIntersectRange.h"

@interface FBBezierContour ()

- (BOOL) contourAndSelfIntersectingContoursContainPoint:(NSPoint)point;
- (void) addSelfIntersectingContoursToArray:(NSMutableArray *)contours originalContour:(FBBezierContour *)originalContour;

@property (readonly) NSArray *selfIntersectingContours;

- (void) startingEdge:(FBBezierCurve **)outEdge parameter:(CGFloat *)outParameter point:(NSPoint *)outPoint;
- (BOOL) markCrossingsOnEdge:(FBBezierCurve *)edge startParameter:(CGFloat)startParameter stopParameter:(CGFloat)stopParameter otherContours:(NSArray *)otherContours isEntry:(BOOL)startIsEntry;

@property (readonly) NSMutableArray *overlaps_;

@end

@implementation FBBezierContour

@synthesize edges=_edges;
@synthesize inside=_inside;

+ (id) bezierContourWithCurve:(FBBezierCurve *)curve
{
    FBBezierContour *contour = [[[FBBezierContour alloc] init] autorelease];
    [contour addCurve:curve];
    return contour;
}

- (id)init
{
    self = [super init];
    if ( self != nil ) {
        _edges = [[NSMutableArray alloc] initWithCapacity:12];
    }
    
    return self;
}

- (void)dealloc
{
    [_edges release];
    [_overlaps release];
    [_bezPathCache release];
    [super dealloc];
}

- (NSMutableArray *) overlaps_
{
    if ( _overlaps == nil )
        _overlaps = [[NSMutableArray alloc] initWithCapacity:12];
    return _overlaps;
}

- (void) addCurve:(FBBezierCurve *)curve
{
    // Add the curve by wrapping it in an edge
    if ( curve == nil )
        return;
    curve.contour = self;
    curve.index = [_edges count];
    [_edges addObject:curve];
    _bounds = NSZeroRect; // force the bounds to be recalculated
    _boundingRect = NSZeroRect;
	[_bezPathCache release];
	_bezPathCache = nil;
}

- (void) addCurveFrom:(FBEdgeCrossing *)startCrossing to:(FBEdgeCrossing *)endCrossing
{
    // First construct the curve that we're going to add, by seeing which crossing
    //  is nil. If the crossing isn't given go to the end of the edge on that side.
    FBBezierCurve *curve = nil;
    if ( startCrossing == nil && endCrossing != nil ) {
        // From start to endCrossing
        curve = endCrossing.leftCurve;
    } else if ( startCrossing != nil && endCrossing == nil ) {
        // From startCrossing to end
        curve = startCrossing.rightCurve;
    } else if ( startCrossing != nil && endCrossing != nil ) {
        // From startCrossing to endCrossing
        curve = [startCrossing.curve subcurveWithRange:FBRangeMake(startCrossing.parameter, endCrossing.parameter)];
    }
    [self addCurve:curve];
}

- (void) addReverseCurve:(FBBezierCurve *)curve
{
    // Just reverse the points on the curve. Need to do this to ensure the end point from one edge, matches the start
    //  on the next edge.
    if ( curve == nil )
        return;

    [self addCurve:[curve reversedCurve]];
}

- (void) addReverseCurveFrom:(FBEdgeCrossing *)startCrossing to:(FBEdgeCrossing *)endCrossing
{
    // First construct the curve that we're going to add, by seeing which crossing
    //  is nil. If the crossing isn't given go to the end of the edge on that side.
    FBBezierCurve *curve = nil;
    if ( startCrossing == nil && endCrossing != nil ) {
        // From start to endCrossing
        curve = endCrossing.leftCurve;
    } else if ( startCrossing != nil && endCrossing == nil ) {
        // From startCrossing to end
        curve = startCrossing.rightCurve;
    } else if ( startCrossing != nil && endCrossing != nil ) {
        // From startCrossing to endCrossing
        curve = [startCrossing.curve subcurveWithRange:FBRangeMake(startCrossing.parameter, endCrossing.parameter)];
    }
    [self addReverseCurve:curve];
}

- (NSRect) bounds
{
    // Cache the bounds to save time
    if ( !NSEqualRects(_bounds, NSZeroRect) )
        return _bounds;
    
    // If no edges, no bounds
    if ( [_edges count] == 0 )
        return NSZeroRect;
    
    NSRect totalBounds = NSZeroRect;    
    for (FBBezierCurve *edge in _edges) {
        NSRect bounds = edge.bounds;
        if ( NSEqualRects(totalBounds, NSZeroRect) )
            totalBounds = bounds;
        else
            totalBounds = FBUnionRect(totalBounds, bounds);
    }
    
    _bounds = totalBounds;

    return _bounds;
}

- (NSRect) boundingRect
{
    // Cache the bounds to save time
    if ( !NSEqualRects(_boundingRect, NSZeroRect) )
        return _boundingRect;
    
    // If no edges, no bounds
    if ( [_edges count] == 0 )
        return NSZeroRect;
    
    NSRect totalBounds = NSZeroRect;
    for (FBBezierCurve *edge in _edges) {
        NSRect bounds = edge.boundingRect;
        if ( NSEqualRects(totalBounds, NSZeroRect) )
            totalBounds = bounds;
        else
            totalBounds = FBUnionRect(totalBounds, bounds);
    }
    
    _boundingRect = totalBounds;
    
    return _boundingRect;
}

- (NSPoint) firstPoint
{
    if ( [_edges count] == 0 )
        return NSZeroPoint;

    FBBezierCurve *edge = [_edges objectAtIndex:0];
    return edge.endPoint1;
}

- (BOOL) containsPoint:(NSPoint)testPoint
{
    if ( !NSPointInRect(testPoint, self.boundingRect) || !NSPointInRect(testPoint, self.bounds) )
        return NO;
    
	// Create a test line from our point to somewhere outside our graph. We'll see how many times the test
    //  line intersects edges of the graph. Based on the even/odd rule, if it's an odd number, we're inside
    //  the graph, if even, outside.
    NSPoint lineEndPoint = NSMakePoint(testPoint.x > NSMinX(self.bounds) ? NSMinX(self.bounds) - 10 : NSMaxX(self.bounds) + 10, testPoint.y); /* just move us outside the bounds of the graph */
    FBBezierCurve *testCurve = [FBBezierCurve bezierCurveWithLineStartPoint:testPoint endPoint:lineEndPoint];
    
    NSUInteger intersectCount = [self numberOfIntersectionsWithRay:testCurve];
    return (intersectCount & 1) == 1;
}

- (NSUInteger) numberOfIntersectionsWithRay:(FBBezierCurve *)testEdge
{
    __block NSUInteger count = 0;
    [self intersectionsWithRay:testEdge withBlock:^(FBBezierIntersection *intersection) {
        count++;
    }];
    return count;
}

- (void) intersectionsWithRay:(FBBezierCurve *)testEdge withBlock:(void (^)(FBBezierIntersection *intersection))block

{
    __block FBBezierIntersection *firstIntersection = nil;
    __block FBBezierIntersection *previousIntersection = nil;
    
    // Count how many times we intersect with this particular contour
    for (FBBezierCurve *edge in _edges) {
        // Check for intersections between our test ray and the rest of the bezier graph
        FBBezierIntersectRange *intersectRange = nil;
        [testEdge intersectionsWithBezierCurve:edge overlapRange:&intersectRange withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
            // Make sure this is a proper crossing
            if ( ![testEdge crossesEdge:edge atIntersection:intersection] || edge.isPoint ) // don't count tangents
                return;
            
            // Make sure we don't count the same intersection twice. This happens when the ray crosses at
            //  start or end of an edge.
            if ( intersection.isAtStartOfCurve2 && previousIntersection != nil ) {
                FBBezierCurve *previousEdge = edge.previous;
                if ( previousIntersection.isAtEndPointOfCurve2 && previousEdge == previousIntersection.curve2 )
                    return;
            } else if ( intersection.isAtEndPointOfCurve2 && firstIntersection != nil ) {
                FBBezierCurve *nextEdge = edge.next;
                if ( firstIntersection.isAtStartOfCurve2 && nextEdge == firstIntersection.curve2 )
                    return;
            }
            
            block(intersection);
            if ( firstIntersection == nil )
                firstIntersection = intersection;
            previousIntersection = intersection;
        }];
        if ( intersectRange != nil && [testEdge crossesEdge:edge atIntersectRange:intersectRange] ) {
            block([intersectRange middleIntersection]);
        }
    }
}

- (FBBezierCurve *) startEdge
{
    // When marking we need to start at a point that is clearly either inside or outside
    //  the other graph, otherwise we could mark the crossings exactly opposite of what
    //  they're supposed to be.
    if ( [self.edges count] == 0 )
        return nil;
    
    FBBezierCurve *startEdge = [self.edges objectAtIndex:0];
    FBBezierCurve *stopValue = startEdge;
    while ( startEdge.isStartShared ) {
        startEdge = startEdge.next;
        if ( startEdge == stopValue )
            break; // for safety. But if we're here, we could be hosed
    }
    return startEdge;
}

- (NSPoint) testPointForContainment
{
    // Start with the startEdge, and if it's not shared (overlapping) then use its first point
    FBBezierCurve *testEdge = self.startEdge;
    if ( !testEdge.isStartShared )
        return testEdge.endPoint1;
    
    // At this point we know that all the end points defining this contour are shared. We'll
    //  need to somewhat arbitrarily pick a point on an edge that's not overlapping
    FBBezierCurve *stopValue = testEdge;
    CGFloat parameter = 0.5;
    while ( [self doesOverlapContainParameter:parameter onEdge:testEdge] ) {
        testEdge = testEdge.next;
        if ( testEdge == stopValue )
            break; // for safety. But if we're here, we could be hosed
    }

    return [testEdge pointAtParameter:parameter leftBezierCurve:nil rightBezierCurve:nil];
}

- (void) startingEdge:(FBBezierCurve **)outEdge parameter:(CGFloat *)outParameter point:(NSPoint *)outPoint
{
    // Start with the startEdge, and if it's not shared (overlapping) then use its first point
    FBBezierCurve *testEdge = self.startEdge;
    if ( !testEdge.isStartShared ) {
        *outEdge = testEdge;
        *outParameter = 0.0;
        *outPoint = testEdge.endPoint1;
        return;
    }
    
    // At this point we know that all the end points defining this contour are shared. We'll
    //  need to somewhat arbitrarily pick a point on an edge that's not overlapping
    FBBezierCurve *stopValue = testEdge;
    CGFloat parameter = 0.5;
    while ( [self doesOverlapContainParameter:parameter onEdge:testEdge] ) {
        testEdge = testEdge.next;
        if ( testEdge == stopValue )
            break; // for safety. But if we're here, we could be hosed
    }

    *outEdge = testEdge;
    *outParameter = parameter;
    *outPoint = [testEdge pointAtParameter:parameter leftBezierCurve:nil rightBezierCurve:nil];
}

- (void) markCrossingsAsEntryOrExitWithContour:(FBBezierContour *)otherContour markInside:(BOOL)markInside
{
    // Go through and mark all the crossings with the given contour as "entry" or "exit". This 
    //  determines what part of ths contour is outputted. 
    
    // When marking we need to start at a point that is clearly either inside or outside
    //  the other graph, otherwise we could mark the crossings exactly opposite of what
    //  they're supposed to be.
    FBBezierCurve *startEdge = nil;
    NSPoint startPoint = NSZeroPoint;
    CGFloat startParameter = 0.0;
    [self startingEdge:&startEdge parameter:&startParameter point:&startPoint];
    
    // Calculate the first entry value. We need to determine if the edge we're starting
    //  on is inside or outside the otherContour.
    BOOL contains = [otherContour contourAndSelfIntersectingContoursContainPoint:startPoint];
    BOOL isEntry = markInside ? !contains : contains;
    NSArray *otherContours = [otherContour.selfIntersectingContours arrayByAddingObject:otherContour];
    
    static const CGFloat FBStopParameterNoLimit = 2.0; // needs to be > 1.0
    static const CGFloat FBStartParameterNoLimit = 0.0;
    
    // Walk all the edges in this contour and mark the crossings
    isEntry = [self markCrossingsOnEdge:startEdge startParameter:startParameter stopParameter:FBStopParameterNoLimit otherContours:otherContours isEntry:isEntry];
    FBBezierCurve *edge = startEdge.next;
    while ( edge != startEdge ) {
        isEntry = [self markCrossingsOnEdge:edge startParameter:FBStartParameterNoLimit stopParameter:FBStopParameterNoLimit otherContours:otherContours isEntry:isEntry];
        edge = edge.next;
    }
    [self markCrossingsOnEdge:startEdge startParameter:FBStartParameterNoLimit stopParameter:startParameter otherContours:otherContours isEntry:isEntry];
}

- (BOOL) markCrossingsOnEdge:(FBBezierCurve *)edge startParameter:(CGFloat)startParameter stopParameter:(CGFloat)stopParameter otherContours:(NSArray *)otherContours isEntry:(BOOL)startIsEntry
{
    __block BOOL isEntry = startIsEntry;
    // Mark all the crossings on this edge
    [edge crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
        // skip over other contours
        if ( crossing.isSelfCrossing || ![otherContours containsObject:crossing.counterpart.edge.contour] )
            return;
        if ( crossing.parameter < startParameter || crossing.parameter >= stopParameter )
            return;
        crossing.entry = isEntry;
        isEntry = !isEntry; // toggle.
    }];
    return isEntry;
}

- (BOOL) contourAndSelfIntersectingContoursContainPoint:(NSPoint)point
{
    NSUInteger containerCount = 0;
    if ( [self containsPoint:point] )
        containerCount++;
    NSArray *intersectingContours = self.selfIntersectingContours;
    for (FBBezierContour *contour in intersectingContours) {
        if ( [contour containsPoint:point] )
            containerCount++;
    }
    return (containerCount & 1) != 0;
}

- (NSBezierPath*) bezierPath		// GPC: added
{
	if ( _bezPathCache == nil ) {
		NSBezierPath* path = [NSBezierPath bezierPath];
		BOOL firstPoint = YES;        
		
		for ( FBBezierCurve *edge in self.edges ) {
			if ( firstPoint ) {
				[path moveToPoint:edge.endPoint1];
				firstPoint = NO;
			}
			
			if ( edge.isStraightLine )
				[path lineToPoint:edge.endPoint2];
			else
				[path curveToPoint:edge.endPoint2 controlPoint1:edge.controlPoint1 controlPoint2:edge.controlPoint2];
		}
		
		[path closePath];
		[path setWindingRule:NSEvenOddWindingRule];
		_bezPathCache = [path retain];
    }
	
    return _bezPathCache;
}


- (void) close
{
	// adds an element to connect first and last points on the contour
	if ( [_edges count] == 0 )
        return;
    
    FBBezierCurve *first = [_edges objectAtIndex:0];
    FBBezierCurve *last = [_edges lastObject];
    
    if ( !FBArePointsClose(first.endPoint1, last.endPoint2) )
        [self addCurve:[FBBezierCurve bezierCurveWithLineStartPoint:last.endPoint2 endPoint:first.endPoint1]];
}


- (FBBezierContour*) reversedContour	// GPC: added
{
	FBBezierContour *revContour = [[[self class] alloc] init];
	
	for ( FBBezierCurve *edge in _edges )
		[revContour addReverseCurve:edge];
	
	return [revContour autorelease];
}


- (FBContourDirection) direction
{
	NSPoint lastPoint = NSZeroPoint, currentPoint = NSZeroPoint;
	BOOL firstPoint = YES;
	CGFloat	a = 0.0;
	
	for ( FBBezierCurve* edge in _edges ) {
		if ( firstPoint ) {
			lastPoint = edge.endPoint1;
			firstPoint = NO;
		} else {
			currentPoint = edge.endPoint2;
			a += ((lastPoint.x * currentPoint.y) - (currentPoint.x * lastPoint.y));
			lastPoint = currentPoint;
		}
	}

	return ( a >= 0 ) ? FBContourClockwise : FBContourAntiClockwise;
}


- (FBBezierContour *) contourMadeClockwiseIfNecessary
{
	FBContourDirection dir = [self direction];
	
	if( dir == FBContourClockwise )
		return self;
	
    return [self reversedContour];
}

- (BOOL) crossesOwnContour:(FBBezierContour *)contour
{
    for (FBBezierCurve *edge in _edges) {
        __block BOOL intersects = NO;
        [edge crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
            if ( !crossing.isSelfCrossing )
                return; // Only want the self intersecting crossings
            FBBezierCurve *intersectingEdge = crossing.counterpart.edge;
            if ( intersectingEdge.contour == contour ) {
                intersects = YES;
                *stop = YES;
            }
        }];
        if ( intersects )
            return YES;
    }
    return NO;
}

- (NSArray *) intersectingContours
{
    // Go and find all the unique contours that intersect this specific contour
    NSMutableArray *contours = [NSMutableArray arrayWithCapacity:3];
    for (FBBezierCurve *edge in _edges) {
        [edge intersectingEdgesWithBlock:^(FBBezierCurve *intersectingEdge) {
            if ( ![contours containsObject:intersectingEdge.contour] )
                [contours addObject:intersectingEdge.contour];
        }];
    }
    return contours;
}

- (NSArray *) selfIntersectingContours
{
    // Go and find all the unique contours that intersect this specific contour from our own graph
    NSMutableArray *contours = [NSMutableArray arrayWithCapacity:3];
    [self addSelfIntersectingContoursToArray:contours originalContour:self];
    return contours;
}

- (void) addSelfIntersectingContoursToArray:(NSMutableArray *)contours originalContour:(FBBezierContour *)originalContour
{
    for (FBBezierCurve *edge in _edges) {
        [edge selfIntersectingEdgesWithBlock:^(FBBezierCurve *intersectingEdge) {
            if ( intersectingEdge.contour != originalContour && ![contours containsObject:intersectingEdge.contour] ) {
                [contours addObject:intersectingEdge.contour];
                [intersectingEdge.contour addSelfIntersectingContoursToArray:contours originalContour:originalContour];
            }
        }];
    }
}

- (void) addOverlap:(FBContourOverlap *)overlap
{
    if ( [overlap isEmpty] )
        return;
    
    [self.overlaps_ addObject:overlap];
}

- (void) removeAllOverlaps
{
    if ( _overlaps == nil )
        return;
    
    [_overlaps removeAllObjects];
}

- (BOOL) isEquivalent:(FBBezierContour *)other
{
    if ( _overlaps == nil )
        return NO;
    
    for (FBContourOverlap *overlap in _overlaps) {
        if ( [overlap isBetweenContour:self andContour:other] && [overlap isComplete] )
            return YES;
    }
    return NO;
}

- (void) forEachEdgeOverlapDo:(void (^)(FBEdgeOverlap *overlap))block
{
    if ( _overlaps == nil )
        return;

    for (FBContourOverlap *overlap in _overlaps) {
        [overlap runsWithBlock:^(FBEdgeOverlapRun *run, BOOL *stop) {
            for (FBEdgeOverlap *edgeOverlap in run.overlaps)
                block(edgeOverlap);
        }];
    }
}

- (BOOL) doesOverlapContainCrossing:(FBEdgeCrossing *)crossing
{
    if ( _overlaps == nil )
        return NO;

    for (FBContourOverlap *overlap in _overlaps) {
        if ( [overlap doesContainCrossing:crossing] )
            return YES;
    }
    return NO;
}

- (BOOL) doesOverlapContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge
{
    if ( _overlaps == nil )
        return NO;

    for (FBContourOverlap *overlap in _overlaps) {
        if ( [overlap doesContainParameter:parameter onEdge:edge] )
            return YES;
    }
    return NO;    
}

- (id)copyWithZone:(NSZone *)zone
{
    FBBezierContour *copy = [[FBBezierContour allocWithZone:zone] init];
    for (FBBezierCurve *edge in _edges)
        [copy addCurve:edge];
    return copy;
}

- (FBCurveLocation *) closestLocationToPoint:(NSPoint)point
{
    FBBezierCurve *closestEdge = nil;
    FBBezierCurveLocation location = {};
    
    for (FBBezierCurve *edge in _edges) {
        FBBezierCurveLocation edgeLocation = [edge closestLocationToPoint:point];
        if ( closestEdge == nil || edgeLocation.distance < location.distance ) {
            closestEdge = edge;
            location = edgeLocation;
        }
    }
    
    if ( closestEdge == nil )
        return nil;
    
    FBCurveLocation *curveLocation = [FBCurveLocation curveLocationWithEdge:closestEdge parameter:location.parameter distance:location.distance];
    curveLocation.contour = self;
    return curveLocation;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: bounds = (%f, %f)(%f, %f) edges = %@>", 
            NSStringFromClass([self class]),
            NSMinX(self.bounds), NSMinY(self.bounds),
            NSWidth(self.bounds), NSHeight(self.bounds),
            FBArrayDescription(_edges)
            ];
}



- (NSBezierPath *) debugPathForIntersectionType:(NSInteger)itersectionType
{
	// returns a path consisting of small circles placed at the intersections that match <ti>
	// this allows the internal state of a contour to be rapidly visualized so that bugs with
	// boolean ops are easier to spot at a glance
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	for ( FBBezierCurve* edge in _edges ) {
        [edge crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
			switch ( itersectionType ) {
				default:	// match any
					break;
                    
				case 1:		// looking for entries
					if ( !crossing.isEntry )
						return;
					break;
					
				case 2:		// looking for exits
					if ( crossing.isEntry )
						return;
					break;
			}
			
			// if the crossing is flagged as "entry", show a circle, otherwise a rectangle
			[path appendBezierPath:crossing.isEntry? [NSBezierPath circleAtPoint:crossing.location] : [NSBezierPath rectAtPoint:crossing.location]];
            
        }];
	}
	
    // Add the start point and direction for marking
    FBBezierCurve *startEdge = [self startEdge];
    NSPoint startEdgeTangent = FBNormalizePoint(FBSubtractPoint(startEdge.controlPoint1, startEdge.endPoint1));
    [path appendBezierPath:[NSBezierPath triangleAtPoint:startEdge.endPoint1 direction:startEdgeTangent]];
    
	// add the contour's entire path to make it easy to see which one owns which crossings (these can be colour-coded when drawing the paths)
	[path appendBezierPath:[self bezierPath]];
	
	// if this countour is flagged as "inside", the debug path is shown dashed, otherwise solid
	if ( self.inside == FBContourInsideHole ) {
        CGFloat dashes[] = { 2, 3 };
		[path setLineDash:dashes count:2 phase:0];
    }
	
	return path;
}

@end
