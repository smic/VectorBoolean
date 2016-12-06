//
//  FBBezierGraph.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierGraph.h"
#import "FBBezierCurve.h"
#import "NSBezierPath+Utilities.h"
#import "FBBezierContour.h"
#import "FBBezierCurve+Edge.h"
#import "FBBezierIntersection.h"
#import "FBEdgeCrossing.h"
#import "FBContourOverlap.h"
#import "FBCurveLocation.h"
#import "FBDebug.h"
#import "FBGeometry.h"
#import <math.h>



//////////////////////////////////////////////////////////////////////////
// FBBezierGraph
//
// The main point of this class is to perform boolean operations. The algorithm
//  used here is a modified and expanded version of the algorithm presented
//  in "Efficient clipping of arbitrary polygons" by Günther Greiner and Kai Hormann.
//  http://www.inf.usi.ch/hormann/papers/Greiner.1998.ECO.pdf
//  That algorithm assumes polygons, not curves, and only considers one contour intersecting
//  one other contour. My algorithm uses bezier curves (not polygons) and handles
//  multiple contours intersecting other contours.
//

@interface FBBezierGraph ()

- (void) removeCrossingsInOverlaps;
- (void) removeDuplicateCrossings;
- (void) insertCrossingsWithBezierGraph:(FBBezierGraph *)other;
- (FBEdgeCrossing *) firstUnprocessedCrossing;
- (void) markCrossingsAsEntryOrExitWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside;
- (FBBezierGraph *) bezierGraphFromIntersections;
- (void) removeCrossings;
- (void) removeOverlaps;
- (void) cleanupCrossingsWithBezierGraph:(FBBezierGraph *)other;

- (void) insertSelfCrossings;
- (void) markAllCrossingsAsUnprocessed;

- (void) unionNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph;
- (void) unionEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results;
- (void) intersectNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph;
- (void) intersectEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results;
- (void) differenceEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results;

- (void) addContour:(FBBezierContour *)contour;
- (FBContourInside) contourInsides:(FBBezierContour *)contour;

- (NSArray *) nonintersectingContours;
- (BOOL) containsContour:(FBBezierContour *)contour;
- (BOOL) eliminateContainers:(NSMutableArray *)containers thatDontContainContour:(FBBezierContour *)testContour usingRay:(FBBezierCurve *)ray;
- (BOOL) findBoundsOfContour:(FBBezierContour *)testContour onRay:(FBBezierCurve *)ray minimum:(NSPoint *)testMinimum maximum:(NSPoint *)testMaximum;
- (void) removeContoursThatDontContain:(NSMutableArray *)crossings;
- (BOOL) findCrossingsOnContainers:(NSArray *)containers onRay:(FBBezierCurve *)ray beforeMinimum:(NSPoint)testMinimum afterMaximum:(NSPoint)testMaximum crossingsBefore:(NSMutableArray *)crossingsBeforeMinimum crossingsAfter:(NSMutableArray *)crossingsAfterMaximum;
- (void) removeCrossings:(NSMutableArray *)crossings forContours:(NSArray *)containersToRemove;
- (void) removeContourCrossings:(NSMutableArray *)crossings1 thatDontAppearIn:(NSMutableArray *)crossings2;
- (NSArray *) contoursFromCrossings:(NSArray *)crossings;
- (NSUInteger) numberOfTimesContour:(FBBezierContour *)contour appearsInCrossings:(NSArray *)crossings;

- (void) debuggingInsertCrossingsWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside markOtherInside:(BOOL)markOtherInside;

//@property (readonly) NSArray *contours;

@end

@implementation FBBezierGraph

@synthesize contours=_contours;

+ (id) bezierGraphWithBezierPath:(NSBezierPath *)path
{
    return [[FBBezierGraph alloc] initWithBezierPath:path];
}

+ (id) bezierGraph
{
    return [[FBBezierGraph alloc] init];
}

- (id) initWithBezierPath:(NSBezierPath *)path
{
    self = [super init];
    
    if ( self != nil ) {
        // A bezier graph is made up of contours, which are closed paths of curves. Anytime we
        //  see a move to in the NSBezierPath, that's a new contour.
		
        NSPoint lastPoint = NSZeroPoint;
		BOOL	wasClosed = NO;
        _contours = [[NSMutableArray alloc] initWithCapacity:2];
            
        FBBezierContour *contour = nil;
        for (NSUInteger i = 0; i < path.elementCount; i++) {
            NSBezierElement element = [path fb_elementAtIndex:i];
            
            switch (element.kind) {
                case NSMoveToBezierPathElement:
				{
                    // if previous contour wasn't closed, close it
					
					if( !wasClosed && contour != nil )
						[contour close];
					
					wasClosed = NO;
										
					// Start a new contour
                    contour = [[FBBezierContour alloc] init];
                    [self addContour:contour];
                    
                    lastPoint = element.point;
                    break;
				}
					
                case NSLineToBezierPathElement: {
                    // [MO] skip degenerate line segments
                    if (!NSEqualPoints(element.point, lastPoint)) {
                        // Convert lines to bezier curves as well. Just set control point to be in the line formed
                        //  by the end points
                        [contour addCurve:[FBBezierCurve bezierCurveWithLineStartPoint:lastPoint endPoint:element.point]];
                        
                        lastPoint = element.point;
                    }
                    break;
                }
                    
                case NSCurveToBezierPathElement:
				{
                    // GPC: skip degenerate case where all points are equal
					
					if( NSEqualPoints( element.point, lastPoint ) && NSEqualPoints( element.point, element.controlPoints[0] ) && NSEqualPoints( element.point, element.controlPoints[1] ))
						continue;

					[contour addCurve:[FBBezierCurve bezierCurveWithEndPoint1:lastPoint controlPoint1:element.controlPoints[0] controlPoint2:element.controlPoints[1] endPoint2:element.point]];
                    
                    lastPoint = element.point;
                    break;
				}   
                case NSClosePathBezierPathElement:
                    // [MO] attempt to close the bezier contour by
                    // mapping closepaths to equivalent lineto operations,
                    // though as with our NSLineToBezierPathElement processing,
                    // we check so as not to add degenerate line segments which 
                    // blow up the clipping code.
                    
                    if (contour.edges.count) {
                        FBBezierCurve *firstEdge = contour.edges[0];
                        NSPoint firstPoint = firstEdge.endPoint1;
                        
                        // Skip degenerate line segments
                        if ( !NSEqualPoints(lastPoint, firstPoint) ) {
                            [contour addCurve:[FBBezierCurve bezierCurveWithLineStartPoint:lastPoint endPoint:firstPoint]];
							wasClosed = YES;
                        }
                    }
                    lastPoint = NSZeroPoint;
                    break;
            }
        }

		if( !wasClosed && contour != nil )
			[contour close];

    }
    
    return self;
}

- (id) init
{
    self = [super init];
    
    if ( self != nil ) {
        _contours = [[NSMutableArray alloc] initWithCapacity:2];
    }
    
    return self;
}


////////////////////////////////////////////////////////////////////////
// Boolean operations
//
// The three main boolean operations (union, intersect, difference) follow
//  much the same algorithm. First, the places where the two graphs cross 
//  (not just intersect) are marked on the graph with FBEdgeCrossing objects.
//  Next, we decide which sections of the two graphs should appear in the final
//  result. (There are only two kind of sections: those inside of the other graph,
//  and those outside.) We do this by walking all the crossings we created
//  and marking them as entering a section that should appear in the final result,
//  or as exiting the final result. We then walk all the crossings again, and
//  actually output the final result of the graphs that intersect.
//
//  The last part of each boolean operation deals with what do with contours
//  in each graph that don't intersect any other contours.
//
// The exclusive or boolean op is implemented in terms of union, intersect,
//  and difference. More specifically it subtracts the intersection of both
//  graphs from the union of both graphs.
//

- (FBBezierGraph *) unionWithBezierGraph:(FBBezierGraph *)graph
{
    // First insert FBEdgeCrossings into both graphs where the graphs
    //  cross.
    [self insertCrossingsWithBezierGraph:graph];
    [self insertSelfCrossings];
    [graph insertSelfCrossings];
    [self cleanupCrossingsWithBezierGraph:graph];
    
    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are outside the other for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:graph markInside:NO];
    [graph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:NO];

    // Walk the crossings and actually compute the final result for the intersecting parts
    FBBezierGraph *result = [self bezierGraphFromIntersections];

    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    [self unionNonintersectingPartsIntoGraph:result withGraph:graph];

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    [self removeCrossings];
    [graph removeCrossings];
    [self removeOverlaps];
    [graph removeOverlaps];

    return result;
}

- (void) unionNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph
{
    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    NSMutableArray *ourNonintersectingContours = [[self nonintersectingContours] mutableCopy];
    NSMutableArray *theirNonintersectinContours = [[graph nonintersectingContours] mutableCopy];
    NSMutableArray *finalNonintersectingContours = [ourNonintersectingContours mutableCopy];
    [finalNonintersectingContours addObjectsFromArray:theirNonintersectinContours];
    [self unionEquivalentNonintersectingContours:ourNonintersectingContours withContours:theirNonintersectinContours results:finalNonintersectingContours];
    
    // Since we're doing a union, assume all the non-crossing contours are in, and remove
    //  by exception when they're contained by another contour.
    for (FBBezierContour *ourContour in ourNonintersectingContours) {
        // If the other graph contains our contour, it's redundant and we can just remove it
        BOOL clipContainsSubject = [graph containsContour:ourContour];
        if ( clipContainsSubject )
            [finalNonintersectingContours removeObject:ourContour];
    }
    for (FBBezierContour *theirContour in theirNonintersectinContours) {
        // If we contain this contour, it's redundant and we can just remove it
        BOOL subjectContainsClip = [self containsContour:theirContour];
        if ( subjectContainsClip )
            [finalNonintersectingContours removeObject:theirContour];
    }
    
    // Append the final nonintersecting contours
    for (FBBezierContour *contour in finalNonintersectingContours)
        [result addContour:contour];
}

- (void) unionEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
{
    for (NSUInteger ourIndex = 0; ourIndex < ourNonintersectingContours.count; ourIndex++) {
        FBBezierContour *ourContour = ourNonintersectingContours[ourIndex];
        for (NSUInteger theirIndex = 0; theirIndex < theirNonintersectingContours.count; theirIndex++) {
            FBBezierContour *theirContour = theirNonintersectingContours[theirIndex];
            
            if ( ![ourContour isEquivalent:theirContour] )
                continue;
        
            if ( ourContour.inside == theirContour.inside ) {
                // Redundant, so just remove one of them from the results
                [results removeObject:theirContour];
            } else {
                // One is a hole, one is a fill, so they cancel each other out. Remove both from the results
                [results removeObject:theirContour];
                [results removeObject:ourContour];
            }
            
            // Remove both from the inputs so they aren't processed later
            [theirNonintersectingContours removeObjectAtIndex:theirIndex];
            [ourNonintersectingContours removeObjectAtIndex:ourIndex];
            ourIndex--;
            break;
        }
    }
}

- (FBBezierGraph *) intersectWithBezierGraph:(FBBezierGraph *)graph
{
    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    [self insertCrossingsWithBezierGraph:graph];
    [self insertSelfCrossings];
    [graph insertSelfCrossings];
    [self cleanupCrossingsWithBezierGraph:graph];

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:graph markInside:YES];
    [graph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:YES];
    
    // Walk the crossings and actually compute the final result for the intersecting parts
    FBBezierGraph *result = [self bezierGraphFromIntersections];
    
    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    [self intersectNonintersectingPartsIntoGraph:result withGraph:graph];
    
    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    [self removeCrossings];
    [graph removeCrossings];
    [self removeOverlaps];
    [graph removeOverlaps];

    return result;
}

- (void) intersectNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph
{
    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    NSMutableArray *ourNonintersectingContours = [[self nonintersectingContours] mutableCopy];
    NSMutableArray *theirNonintersectinContours = [[graph nonintersectingContours] mutableCopy];
    NSMutableArray *finalNonintersectingContours = [NSMutableArray arrayWithCapacity:ourNonintersectingContours.count + theirNonintersectinContours.count];
    [self intersectEquivalentNonintersectingContours:ourNonintersectingContours withContours:theirNonintersectinContours results:finalNonintersectingContours];
    // Since we're doing an intersect, assume that most of these non-crossing contours shouldn't be in
    //  the final result.
    for (FBBezierContour *ourContour in ourNonintersectingContours) {
        // If their graph contains ourContour, then the two graphs intersect (logical AND) at ourContour, so
        //  add it to the final result.
        BOOL clipContainsSubject = [graph containsContour:ourContour];
        if ( clipContainsSubject )
            [finalNonintersectingContours addObject:ourContour];
    }
    for (FBBezierContour *theirContour in theirNonintersectinContours) {
        // If we contain theirContour, then the two graphs intersect (logical AND) at theirContour,
        //  so add it to the final result.
        BOOL subjectContainsClip = [self containsContour:theirContour];
        if ( subjectContainsClip )
            [finalNonintersectingContours addObject:theirContour];
    }
    
    // Append the final nonintersecting contours
    for (FBBezierContour *contour in finalNonintersectingContours)
        [result addContour:contour];
}

- (void) intersectEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
{
    for (NSUInteger ourIndex = 0; ourIndex < ourNonintersectingContours.count; ourIndex++) {
        FBBezierContour *ourContour = ourNonintersectingContours[ourIndex];
        for (NSUInteger theirIndex = 0; theirIndex < theirNonintersectingContours.count; theirIndex++) {
            FBBezierContour *theirContour = theirNonintersectingContours[theirIndex];
            
            if ( ![ourContour isEquivalent:theirContour] )
                continue;
            
            if ( ourContour.inside == theirContour.inside ) {
                // Redundant, so just add one of them to our results
                [results addObject:ourContour];
            } else {
                // One is a hole, one is a fill, so the hole cancels the fill. Add the hole to the results
                if ( theirContour.inside == FBContourInsideHole ) {
                    // theirContour is the hole, so add it
                    [results addObject:theirContour];
                } else {
                    // ourContour is the hole, so add it
                    [results addObject:ourContour];
                }
            }
            
            // Remove both from the inputs so they aren't processed later
            [theirNonintersectingContours removeObjectAtIndex:theirIndex];
            [ourNonintersectingContours removeObjectAtIndex:ourIndex];
            ourIndex--;
            break;
        }
    }
}

- (FBBezierGraph *) differenceWithBezierGraph:(FBBezierGraph *)graph
{
    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    [self insertCrossingsWithBezierGraph:graph];
    [self insertSelfCrossings];
    [graph insertSelfCrossings];
    [self cleanupCrossingsWithBezierGraph:graph];

    // Handle the parts of the graphs that intersect first. We're subtracting
    //  graph from outselves. Mark the outside parts of ourselves, and the inside
    //  parts of them for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:graph markInside:NO];
    [graph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:YES];
    
    // Walk the crossings and actually compute the final result for the intersecting parts
    FBBezierGraph *result = [self bezierGraphFromIntersections];
    
    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    NSMutableArray *ourNonintersectingContours = [[self nonintersectingContours] mutableCopy];
    NSMutableArray *theirNonintersectinContours = [[graph nonintersectingContours] mutableCopy];
    NSMutableArray *finalNonintersectingContours = [NSMutableArray arrayWithCapacity:ourNonintersectingContours.count + theirNonintersectinContours.count];
    [self differenceEquivalentNonintersectingContours:ourNonintersectingContours withContours:theirNonintersectinContours results:finalNonintersectingContours];
    
    // We're doing an subtraction, so assume none of the contours should be in the final result
    for (FBBezierContour *ourContour in ourNonintersectingContours) {
        // If ourContour isn't subtracted away (contained by) the other graph, it should stick around,
        //  so add it to our final result.
        BOOL clipContainsSubject = [graph containsContour:ourContour];
        if ( !clipContainsSubject )
            [finalNonintersectingContours addObject:ourContour];
    }
    for (FBBezierContour *theirContour in theirNonintersectinContours) {
        // If our graph contains theirContour, then add theirContour as a hole.
        BOOL subjectContainsClip = [self containsContour:theirContour];
        if ( subjectContainsClip )
            [finalNonintersectingContours addObject:theirContour]; // add it as a hole
    }
    
    // Append the final nonintersecting contours
    for (FBBezierContour *contour in finalNonintersectingContours)
        [result addContour:contour];
    
    // Clean up crossings so the graphs can be reused
    [self removeCrossings];
    [graph removeCrossings];
    [self removeOverlaps];
    [graph removeOverlaps];

    return result;  
}

- (void) differenceEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
{
    for (NSUInteger ourIndex = 0; ourIndex < ourNonintersectingContours.count; ourIndex++) {
        FBBezierContour *ourContour = ourNonintersectingContours[ourIndex];
        for (NSUInteger theirIndex = 0; theirIndex < theirNonintersectingContours.count; theirIndex++) {
            FBBezierContour *theirContour = theirNonintersectingContours[theirIndex];
            
            if ( ![ourContour isEquivalent:theirContour] )
                continue;
            
            if ( ourContour.inside != theirContour.inside ) {
                // Trying to subtract a hole from a fill or vice versa does nothing, so add the original to the results
                [results addObject:ourContour];
            } else if ( ourContour.inside == FBContourInsideHole && theirContour.inside == FBContourInsideHole ) {
                // Subtracting a hole from a hole is redundant, so just add one of them to the results
                [results addObject:ourContour];
            } else {
                // Both are fills, and subtracting a fill from a fill removes both. So add neither to the results
                //  Intentionally do nothing for this case.
            }
            
            // Remove both from the inputs so they aren't processed later
            [theirNonintersectingContours removeObjectAtIndex:theirIndex];
            [ourNonintersectingContours removeObjectAtIndex:ourIndex];
            ourIndex--;
            break;
        }
    }
}

- (void) markCrossingsAsEntryOrExitWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside
{
    // Walk each contour in ourself and mark the crossings with each intersecting contour as entering
    //  or exiting the final contour.
    for (FBBezierContour *contour in self.contours) {
        NSArray *intersectingContours = contour.intersectingContours;
        for (FBBezierContour *otherContour in intersectingContours) {
            // If the other contour is a hole, that's a special case where we flip marking inside/outside.
            //  For example, if we're doing a union, we'd normally mark the outside of contours. But
            //  if we're unioning with a hole, we want to cut into that hole so we mark the inside instead
            //  of outside.
            if ( otherContour.inside == FBContourInsideHole )
                [contour markCrossingsAsEntryOrExitWithContour:otherContour markInside:!markInside];
            else
                [contour markCrossingsAsEntryOrExitWithContour:otherContour markInside:markInside];
        }
    }
}

- (FBBezierGraph *) xorWithBezierGraph:(FBBezierGraph *)graph
{
    // XOR is done by combing union (OR), intersect (AND) and difference. Specifically
    //  we compute the union of the two graphs, the intersect of them, then subtract
    //  the intersect from the union.
    // Note that we reuse the resulting graphs, which is why it is important that operations
    //  clean up any crossings when their done, otherwise they could interfere with subsequent
    //  operations.
    
    // First insert FBEdgeCrossings into both graphs where the graphs
    //  cross.
    [self insertCrossingsWithBezierGraph:graph];
    [self insertSelfCrossings];
    [graph insertSelfCrossings];
    [self cleanupCrossingsWithBezierGraph:graph];

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are outside the other for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:graph markInside:NO];
    [graph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:NO];

    // Walk the crossings and actually compute the final result for the intersecting parts
    FBBezierGraph *allParts = [self bezierGraphFromIntersections];
    [self unionNonintersectingPartsIntoGraph:allParts withGraph:graph];
    
    [self markAllCrossingsAsUnprocessed];
    [graph markAllCrossingsAsUnprocessed];
    
    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:graph markInside:YES];
    [graph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:YES];

    FBBezierGraph *intersectingParts = [self bezierGraphFromIntersections];
    [self intersectNonintersectingPartsIntoGraph:intersectingParts withGraph:graph];
    
    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    [self removeCrossings];
    [graph removeCrossings];
    [self removeOverlaps];
    [graph removeOverlaps];

    return [allParts differenceWithBezierGraph:intersectingParts];
}

- (NSBezierPath *) bezierPath
{
    // Convert this graph into a bezier path. This is straightforward, each contour
    //  starting with a move to and each subsequent edge being translated by doing
    //  a curve to.
    // Be sure to mark the winding rule as even odd, or interior contours (holes)
    //  won't get filled/left alone properly.
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.windingRule = NSEvenOddWindingRule;

    for (FBBezierContour *contour in _contours) 
	{
        BOOL firstPoint = YES;        
        for (FBBezierCurve *edge in contour.edges)
		{
            if ( firstPoint ) {
                [path moveToPoint:edge.endPoint1];
                firstPoint = NO;
            }
            
			if( edge.isStraightLine)
				[path lineToPoint:edge.endPoint2];
			else
				[path curveToPoint:edge.endPoint2 controlPoint1:edge.controlPoint1 controlPoint2:edge.controlPoint2];
        }
		[path closePath];	// GPC: close each contour
    }
    
    return path;
}

- (void) insertCrossingsWithBezierGraph:(FBBezierGraph *)other
{
    // Find all intersections and, if they cross the other graph, create crossings for them, and insert
    //  them into each graph's edges.
    for (FBBezierContour *ourContour in self.contours) {
        for (FBBezierContour *theirContour in other.contours) {
            FBContourOverlap *overlap = [FBContourOverlap contourOverlap];

            for (FBBezierCurve *ourEdge in ourContour.edges) {
               for (FBBezierCurve *theirEdge in theirContour.edges) {
                    // Find all intersections between these two edges (curves)
                    FBBezierIntersectRange *intersectRange = nil;
                    [ourEdge intersectionsWithBezierCurve:theirEdge overlapRange:&intersectRange withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                        // If this intersection happens at one of the ends of the edges, then mark
                        //  that on the edge. We do this here because not all intersections create
                        //  crossings, but we still need to know when the intersections fall on end points
                        //  later on in the algorithm.
                        if ( intersection.isAtStartOfCurve1 )
                            ourEdge.startShared = YES;
                        if ( intersection.isAtStopOfCurve1 )
                            ourEdge.next.startShared = YES;
                        if ( intersection.isAtStartOfCurve2 )
                            theirEdge.startShared = YES;
                        if ( intersection.isAtStopOfCurve2 )
                            theirEdge.next.startShared = YES;
                        
                        // Don't add a crossing unless one edge actually crosses the other
                        if ( ![ourEdge crossesEdge:theirEdge atIntersection:intersection] )
                            return;
                        
                        // Add crossings to both graphs for this intersection, and point them at each other
                        FBEdgeCrossing *ourCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        FBEdgeCrossing *theirCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        ourCrossing.counterpart = theirCrossing;
                        theirCrossing.counterpart = ourCrossing;
                        [ourEdge addCrossing:ourCrossing];
                        [theirEdge addCrossing:theirCrossing];

                    }];
                    if ( intersectRange != nil )
                        [overlap addOverlap:intersectRange forEdge1:ourEdge edge2:theirEdge];
                } // end theirEdges                
            } //end ourEdges
            
            // At this point we've found all intersections/overlaps between ourContour and theirContour
            
            // Determine if the overlaps constitute crossings
            if ( ![overlap isComplete] ) {
                // The contours aren't equivalent so see if they're crossings
                [overlap runsWithBlock:^(FBEdgeOverlapRun *run, BOOL *stop) {
                    if ( ![run isCrossing] )
                        return;
                    
                    // The two ends of the overlap run should serve as crossings
                    [run addCrossings];
                }];
            }
            
            [ourContour addOverlap:overlap];
            [theirContour addOverlap:overlap];
        } // end theirContours
    } // end ourContours 
}

- (void) cleanupCrossingsWithBezierGraph:(FBBezierGraph *)other
{
    // Remove duplicate crossings that can happen at end points of edges
    [self removeDuplicateCrossings];
    [other removeDuplicateCrossings];
    // Remove crossings that happen in the middle of overlaps that aren't crossings themselves
    [self removeCrossingsInOverlaps];
    [other removeCrossingsInOverlaps];
}

- (void) removeCrossingsInOverlaps
{
    for (FBBezierContour *ourContour in self.contours) {
        for (FBBezierCurve *ourEdge in ourContour.edges) {
            [ourEdge crossingsCopyWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
                if ( crossing.fromCrossingOverlap )
                    return;
                
                if ( [ourContour doesOverlapContainCrossing:crossing] ) {
                    FBEdgeCrossing *counterpart = crossing.counterpart;
                    [crossing removeFromEdge];
                    [counterpart removeFromEdge];
                }                
            }];
        }
    }
}

- (void) removeDuplicateCrossings
{
    // Find any duplicate crossings. These will happen at the endpoints of edges. 
    for (FBBezierContour *ourContour in self.contours) {
        for (FBBezierCurve *ourEdge in ourContour.edges) {
            [ourEdge crossingsCopyWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
                if ( crossing.isAtStart && crossing.edge.previous.lastCrossing.isAtEnd ) {
                    // Found a duplicate. Remove this crossing and its counterpart
                    FBEdgeCrossing *counterpart = crossing.counterpart;
                    [crossing removeFromEdge];
                    [counterpart removeFromEdge];
                }
                if ( crossing.isAtEnd && crossing.edge.next.firstCrossing.isAtStart ) {
                    // Found a duplicate. Remove this crossing and its counterpart
                    FBEdgeCrossing *counterpart = crossing.edge.next.firstCrossing.counterpart;
                    [crossing.edge.next.firstCrossing removeFromEdge];
                    [counterpart removeFromEdge];
                }
            }];
        }
    }
}

- (void) insertSelfCrossings
{
    // Find all intersections and, if they cross other contours in this graph, create crossings for them, and insert
    //  them into each contour's edges.
    NSMutableArray *remainingContours = [self.contours mutableCopy];
    while ( remainingContours.count > 0 ) {
        FBBezierContour *firstContour = remainingContours.lastObject;
        for (FBBezierContour *secondContour in remainingContours) {
            // We don't handle self-intersections on the contour this way, so skip them here
            if ( firstContour == secondContour )
                continue;

            if ( !FBLineBoundsMightOverlap(firstContour.boundingRect, secondContour.boundingRect) || !FBLineBoundsMightOverlap(firstContour.bounds, secondContour.bounds) )
                continue;
            
            // Compare all the edges between these two contours looking for crossings
            for (FBBezierCurve *firstEdge in firstContour.edges) {
                for (FBBezierCurve *secondEdge in secondContour.edges) {
                    // Find all intersections between these two edges (curves)
                    [firstEdge intersectionsWithBezierCurve:secondEdge overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                        // If this intersection happens at one of the ends of the edges, then mark
                        //  that on the edge. We do this here because not all intersections create
                        //  crossings, but we still need to know when the intersections fall on end points
                        //  later on in the algorithm.
                        if ( intersection.isAtStartOfCurve1 )
                            firstEdge.startShared = YES;
                        else if ( intersection.isAtStopOfCurve1 )
                            firstEdge.next.startShared = YES;
                        if ( intersection.isAtStartOfCurve2 )
                            secondEdge.startShared = YES;
                        else if ( intersection.isAtStopOfCurve2 )
                            secondEdge.next.startShared = YES;
                        
                        // Don't add a crossing unless one edge actually crosses the other
                        if ( ![firstEdge crossesEdge:secondEdge atIntersection:intersection] )
                            return;
                        
                        // Add crossings to both graphs for this intersection, and point them at each other
                        FBEdgeCrossing *firstCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        FBEdgeCrossing *secondCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        firstCrossing.selfCrossing = YES;
                        secondCrossing.selfCrossing = YES;
                        firstCrossing.counterpart = secondCrossing;
                        secondCrossing.counterpart = firstCrossing;
                        [firstEdge addCrossing:firstCrossing];
                        [secondEdge addCrossing:secondCrossing];
                    }];
                }
            }
        }
        
        // We just compared this contour to all the others, so we don't need to do it again
        [remainingContours removeLastObject]; // do this at the end of the loop when we're done with it
    }
        
    // Go through and mark each contour if its a hole or filled region
    for (FBBezierContour *contour in _contours)
        contour.inside = [self contourInsides:contour];
}

- (NSRect) bounds
{
    // Compute the bounds of the graph by unioning together the bounds of the individual contours
    if ( !NSEqualRects(_bounds, NSZeroRect) )
        return _bounds;
    if ( _contours.count == 0 )
        return NSZeroRect;
    
    for (FBBezierContour *contour in _contours)
        _bounds = NSUnionRect(_bounds, contour.bounds);
    
    return _bounds;
}


- (FBContourInside) contourInsides:(FBBezierContour *)testContour
{
    // Determine if this contour, which should reside in this graph, is a filled region or
    //  a hole. Determine this by casting a ray from one edges of the contour to the outside of
    //  the entire graph. Count how many times the ray intersects a contour in the graph. If it's
    //  an odd number, the test contour resides inside of filled region, meaning it must be a hole.
    //  Otherwise it's "outside" of the graph and creates a filled region.
    // Create the line from the first point in the contour to outside the graph
    
    // NOTE: this method requires insertSelfCrossings: to be call before it, and the self crossings
    //  to be in place to work
    
    NSPoint testPoint = testContour.testPointForContainment;
    NSPoint lineEndPoint = NSMakePoint(testPoint.x > NSMinX(self.bounds) ? NSMinX(self.bounds) - 10 : NSMaxX(self.bounds) + 10, testPoint.y); /* just move us outside the bounds of the graph */
    FBBezierCurve *testCurve = [FBBezierCurve bezierCurveWithLineStartPoint:testPoint endPoint:lineEndPoint];

    NSUInteger intersectCount = 0;
    for (FBBezierContour *contour in self.contours) {
        if ( contour == testContour || [contour crossesOwnContour:testContour] )
            continue; // don't test self intersections        

        intersectCount += [contour numberOfIntersectionsWithRay:testCurve];
    }
    return (intersectCount & 1) == 1 ? FBContourInsideHole : FBContourInsideFilled;
}

- (FBCurveLocation *) closestLocationToPoint:(NSPoint)point
{
    FBCurveLocation *closestLocation = nil;
    
    for (FBBezierContour *contour in _contours) {
        FBCurveLocation *contourLocation = [contour closestLocationToPoint:point];
        if ( contourLocation != nil && (closestLocation == nil || contourLocation.distance < closestLocation.distance) ) {
            closestLocation = contourLocation;
        }
    }
    
    if ( closestLocation == nil )
        return nil;
    
    closestLocation.graph = self;
    return closestLocation;
}

- (NSBezierPath *) debugPathForContainmentOfContour:(FBBezierContour *)testContour
{
    return [self debugPathForContainmentOfContour:testContour transform:[NSAffineTransform transform]];
}

- (NSBezierPath *) debugPathForContainmentOfContour:(FBBezierContour *)testContour transform:(NSAffineTransform *)transform
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    __block NSUInteger intersectCount = 0;
    for (FBBezierContour *contour in self.contours) {
        if ( contour == testContour )
            continue; // don't test self intersections 
        
        // Check for self-intersections between this contour and other contours in the same graph
        //  If there are intersections, then don't consider the intersecting contour for the purpose
        //  of determining if we are "filled" or a "hole"
        __block BOOL intersectsWithThisContour = NO;
        for (FBBezierCurve *edge in contour.edges) {
            for (FBBezierCurve *oneTestEdge in testContour.edges) {
                [oneTestEdge intersectionsWithBezierCurve:edge overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                    // These are important so startEdge below doesn't pick an ambigious point as a test
                    if ( intersection.isAtStartOfCurve1 )
                        oneTestEdge.startShared = YES;
                    else if ( intersection.isAtStopOfCurve1 )
                        oneTestEdge.next.startShared = YES;
                    if ( intersection.isAtStartOfCurve2 )
                        edge.startShared = YES;
                    else if ( intersection.isAtStopOfCurve2 )
                        edge.next.startShared = YES;

                    if ( ![oneTestEdge crossesEdge:edge atIntersection:intersection] )
                        return;
                    
                    intersectsWithThisContour = YES;
                }];
            }
        }
        if ( intersectsWithThisContour )
            continue; // skip it
        
        // Count how many times we intersect with this particular contour
        // Create the line from the first point in the contour to outside the graph
        NSPoint testPoint = testContour.testPointForContainment;
        
        NSPoint lineEndPoint = NSMakePoint(testPoint.x > NSMinX(self.bounds) ? NSMinX(self.bounds) - 10 : NSMaxX(self.bounds) + 10, testPoint.y); /* just move us outside the bounds of the graph */
        FBBezierCurve *testCurve = [FBBezierCurve bezierCurveWithLineStartPoint:testPoint endPoint:lineEndPoint];

        [contour intersectionsWithRay:testCurve withBlock:^(FBBezierIntersection *intersection) {
            [path appendBezierPath:[NSBezierPath circleAtPoint:[transform transformPoint:intersection.location]]];
            intersectCount++;
        }];
    }

    // add the contour's entire path to make it easy to see which one owns which crossings (these can be colour-coded when drawing the paths)
    {
        NSPoint testPoint = testContour.testPointForContainment;
        
        NSPoint lineEndPoint = NSMakePoint(testPoint.x > NSMinX(self.bounds) ? NSMinX(self.bounds) - 10 : NSMaxX(self.bounds) + 10, testPoint.y); /* just move us outside the bounds of the graph */
        FBBezierCurve *testCurve = [FBBezierCurve bezierCurveWithLineStartPoint:testPoint endPoint:lineEndPoint];
        [path appendBezierPath:[transform transformBezierPath:[testCurve bezierPath]]];
    }
	
	// if this countour is flagged as "inside", the debug path is shown dashed, otherwise solid
	if ( (intersectCount & 1) == 1 ) {
        CGFloat dashes[] = { 2, 3 };
		[path setLineDash:dashes count:2 phase:0];
    }

    return path;
}


- (NSBezierPath *) debugPathForJointsOfContour:(FBBezierContour *)testContour
{
    NSBezierPath *path = [NSBezierPath bezierPath];

    for (FBBezierCurve *edge in testContour.edges) {
        if ( !edge.isStraightLine ) {
            [path moveToPoint:edge.endPoint1];
            [path lineToPoint:edge.controlPoint1];
            [path appendBezierPath:[NSBezierPath smallCircleAtPoint:edge.controlPoint1]];
            [path moveToPoint:edge.endPoint2];
            [path lineToPoint:edge.controlPoint2];
            [path appendBezierPath:[NSBezierPath smallCircleAtPoint:edge.controlPoint2]];            
        }
        [path appendBezierPath:[NSBezierPath smallRectAtPoint:edge.endPoint2]];
    }    

    return path;
}

- (BOOL) containsContour:(FBBezierContour *)testContour
{
    // Determine the container, if any, for the test contour. We do this by casting a ray from one end of the graph to the other,
    //  and recording the intersections before and after the test contour. If the ray intersects with a contour an odd number of 
    //  times on one side, we know it contains the test contour. After determine which contours contain the test contour, we simply
    //  pick the closest one to test contour.
    //
    // Things get a bit more complicated though. If contour shares and edge the test contour, then it can be impossible to determine
    //  whom contains whom. Or if we hit the test contour at a location where edges joint together (i.e. end points).
    //  For this reason, we sit in a loop passing both horizontal and vertical rays through the graph until we can eliminate the number
    //  of potentially enclosing contours down to 1 or 0. Most times the first ray will find the correct answer, but in some degenerate
    //  cases it will take a few iterations.
    
    static const CGFloat FBRayOverlap = 10.0;
    
    // Do a relatively cheap bounds test first
    if ( !FBLineBoundsMightOverlap(self.bounds, testContour.bounds) )
        return NO;
    
    // In the beginning all our contours are possible containers for the test contour.
    NSMutableArray *containers = [_contours mutableCopy];
    
    // Each time through the loop we split the test contour into any increasing amount of pieces
    //  (halves, thirds, quarters, etc) and send a ray along the boundaries. In order to increase
    //  our changes of eliminate all but 1 of the contours, we do both horizontal and vertical rays.
    NSUInteger count = MAX((NSUInteger)ceil(NSWidth(testContour.bounds)), (NSUInteger)ceil(NSHeight(testContour.bounds)));
    for (NSUInteger fraction = 2; fraction <= (count * 2); fraction++) {
        BOOL didEliminate = NO;
        
        // Send the horizontal rays through the test contour and (possibly) through parts of the graph
        CGFloat verticalSpacing = NSHeight(testContour.bounds) / (CGFloat)fraction;
        for (CGFloat y = NSMinY(testContour.bounds) + verticalSpacing; y < NSMaxY(testContour.bounds); y += verticalSpacing) {
            // Construct a line that will reach outside both ends of both the test contour and graph
            FBBezierCurve *ray = [FBBezierCurve bezierCurveWithLineStartPoint:NSMakePoint(MIN(NSMinX(self.bounds), NSMinX(testContour.bounds)) - FBRayOverlap, y) endPoint:NSMakePoint(MAX(NSMaxX(self.bounds), NSMaxX(testContour.bounds)) + FBRayOverlap, y)];
            // Eliminate any contours that aren't containers. It's possible for this method to fail, so check the return
            BOOL eliminated = [self eliminateContainers:containers thatDontContainContour:testContour usingRay:ray];
            if ( eliminated )
                didEliminate = YES;
        }

        // Send the vertical rays through the test contour and (possibly) through parts of the graph
        CGFloat horizontalSpacing = NSWidth(testContour.bounds) / (CGFloat)fraction;
        for (CGFloat x = NSMinX(testContour.bounds) + horizontalSpacing; x < NSMaxX(testContour.bounds); x += horizontalSpacing) {
            // Construct a line that will reach outside both ends of both the test contour and graph
            FBBezierCurve *ray = [FBBezierCurve bezierCurveWithLineStartPoint:NSMakePoint(x, MIN(NSMinY(self.bounds), NSMinY(testContour.bounds)) - FBRayOverlap) endPoint:NSMakePoint(x, MAX(NSMaxY(self.bounds), NSMaxY(testContour.bounds)) + FBRayOverlap)];
            // Eliminate any contours that aren't containers. It's possible for this method to fail, so check the return
            BOOL eliminated = [self eliminateContainers:containers thatDontContainContour:testContour usingRay:ray];
            if ( eliminated )
                didEliminate = YES;
        }
        
        // If we've eliminated all the contours, then nothing contains the test contour, and we're done
        if ( containers.count == 0 )
            return NO;
        // We were able to eliminate someone, and we're down to one, so we're done. If the eliminateContainers: method
        //  failed, we can't make any assumptions about the contains, so just let it go again.
        if ( didEliminate ) 
            return (containers.count & 1) == 1;
    }

    // This is a curious case, because by now we've sent rays that went through every integral cordinate of the test contour.
    //  Despite that eliminateContainers: failed each time, meaning one container has a shared edge for each ray test. It is likely
    //  that contour is equal (the same) as the test contour. Return nil, because if it is equal, it doesn't contain.
    return NO;
}

- (BOOL) findBoundsOfContour:(FBBezierContour *)testContour onRay:(FBBezierCurve *)ray minimum:(NSPoint *)testMinimum maximum:(NSPoint *)testMaximum
{
    // Find the bounds of test contour that lie on ray. Simply intersect the ray with test contour. For a horizontal ray, the minimum is the point
    //  with the lowest x value, the maximum with the highest x value. For a vertical ray, use the high and low y values.
    
    BOOL horizontalRay = ray.endPoint1.y == ray.endPoint2.y; // ray has to be a vertical or horizontal line
    
    // First find all the intersections with the ray
    NSMutableArray *rayIntersections = [NSMutableArray arrayWithCapacity:9];
    for (FBBezierCurve *edge in testContour.edges) {
        [ray intersectionsWithBezierCurve:edge overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
            [rayIntersections addObject:intersection];
        }];
    }
    if ( rayIntersections.count == 0 )
        return NO; // shouldn't happen
    
    // Next go through and find the lowest and highest
    FBBezierIntersection *firstRayIntersection = rayIntersections.firstObject;
    *testMinimum = firstRayIntersection.location;
    *testMaximum = *testMinimum;    
    for (FBBezierIntersection *intersection in rayIntersections) {
        if ( horizontalRay ) {
            if ( intersection.location.x < testMinimum->x )
                *testMinimum = intersection.location;
            if ( intersection.location.x > testMaximum->x )
                *testMaximum = intersection.location;
        } else {
            if ( intersection.location.y < testMinimum->y )
                *testMinimum = intersection.location;
            if ( intersection.location.y > testMaximum->y )
                *testMaximum = intersection.location;            
        }
    }
    return YES;
}

- (BOOL) findCrossingsOnContainers:(NSArray *)containers onRay:(FBBezierCurve *)ray beforeMinimum:(NSPoint)testMinimum afterMaximum:(NSPoint)testMaximum crossingsBefore:(NSMutableArray *)crossingsBeforeMinimum crossingsAfter:(NSMutableArray *)crossingsAfterMaximum
{
    // Find intersections where the ray intersects the possible containers, before the minimum point, or after the maximum point. Store these
    //  as FBEdgeCrossings in the out parameters.
    BOOL horizontalRay = ray.endPoint1.y == ray.endPoint2.y; // ray has to be a vertical or horizontal line

    // Walk through each possible container, one at a time and see where it intersects
    NSMutableArray *ambiguousCrossings = [NSMutableArray arrayWithCapacity:10];
    for (FBBezierContour *container in containers) {
        for (FBBezierCurve *containerEdge in container.edges) {
            // See where the ray intersects this particular edge
            __block BOOL ambigious = NO;
            [ray intersectionsWithBezierCurve:containerEdge overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                if ( intersection.isTangent )
                    return; // tangents don't count
                
                // If the ray intersects one of the contours at a joint (end point), then we won't be able
                //  to make any accurate conclusions, so bail now, and say we failed.
                if ( intersection.isAtEndPointOfCurve2 ) {
                    ambigious = YES;
                    *stop = YES;
                    return;
                }
                
                // If the point likes inside the min and max bounds specified, just skip over it. We only want to remember
                //  the intersections that fall on or outside of the min and max.
                if ( horizontalRay && FBIsValueLessThan(intersection.location.x, testMaximum.x) && FBIsValueGreaterThan(intersection.location.x, testMinimum.x) )
                    return;
                else if ( !horizontalRay && FBIsValueLessThan(intersection.location.y, testMaximum.y) && FBIsValueGreaterThan(intersection.location.y, testMinimum.y) )
                    return;
                
                // Creat a crossing for it so we know what edge it is associated with. Don't insert it into a graph or anything though.
                FBEdgeCrossing *crossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                crossing.edge = containerEdge;
                
                // Special case if the bounds are just a point, and this crossing is on that point. In that case
                //  it could fall on either side, and we'll need to do some special processing on it later. For now,
                //  remember it, and move on to the next intersection.
                if ( NSEqualPoints(testMaximum, testMinimum) && NSEqualPoints(testMaximum, intersection.location) ) {
                    [ambiguousCrossings addObject:crossing];
                    return;
                }
                
                // This crossing falls outse the bounds, so add it to the appropriate array
                
                if ( horizontalRay && FBIsValueLessThanEqual(intersection.location.x, testMinimum.x) )
                    [crossingsBeforeMinimum addObject:crossing];
                else if ( !horizontalRay && FBIsValueLessThanEqual(intersection.location.y, testMinimum.y) )
                    [crossingsBeforeMinimum addObject:crossing];
                if ( horizontalRay && FBIsValueGreaterThanEqual(intersection.location.x, testMaximum.x) )
                    [crossingsAfterMaximum addObject:crossing];
                else if ( !horizontalRay && FBIsValueGreaterThanEqual(intersection.location.y, testMaximum.y) )
                    [crossingsAfterMaximum addObject:crossing];
            }];
            if ( ambigious )
                return NO;
        }
    }
    
    // Handle any intersects that are ambigious. i.e. the min and max are one point, and the intersection is on that point.
    for (FBEdgeCrossing *ambiguousCrossing in ambiguousCrossings) {
        // See how many times the given contour crosses on each side. Add the ambigious crossing to the side that has less,
        //  in hopes of balancing it out.
        NSUInteger numberOfTimesContourAppearsBefore = [self numberOfTimesContour:ambiguousCrossing.edge.contour appearsInCrossings:crossingsBeforeMinimum];
        NSUInteger numberOfTimesContourAppearsAfter = [self numberOfTimesContour:ambiguousCrossing.edge.contour appearsInCrossings:crossingsAfterMaximum];
        if ( numberOfTimesContourAppearsBefore < numberOfTimesContourAppearsAfter )
            [crossingsBeforeMinimum addObject:ambiguousCrossing];
        else
            [crossingsAfterMaximum addObject:ambiguousCrossing];            
    }
    
    return YES;
}

- (NSUInteger) numberOfTimesContour:(FBBezierContour *)contour appearsInCrossings:(NSArray *)crossings
{
    // Count how many times a contour appears in a crossings array
    NSUInteger count = 0;
    for (FBEdgeCrossing *crossing in crossings) {
        if ( crossing.edge.contour == contour )
            count++;
    }
    return count;
}

- (BOOL) eliminateContainers:(NSMutableArray *)containers thatDontContainContour:(FBBezierContour *)testContour usingRay:(FBBezierCurve *)ray
{
    // This method attempts to eliminate all or all but one of the containers that might contain test contour, using the ray specified.
    
    // First determine the exterior bounds of testContour on the given ray
    NSPoint testMinimum = NSZeroPoint;
    NSPoint testMaximum = NSZeroPoint;    
    BOOL foundBounds = [self findBoundsOfContour:testContour onRay:ray minimum:&testMinimum maximum:&testMaximum];
    if ( !foundBounds)
        return NO;
    
    // Find all the containers on either side of the otherContour
    NSMutableArray *crossingsBeforeMinimum = [NSMutableArray arrayWithCapacity:containers.count];
    NSMutableArray *crossingsAfterMaximum = [NSMutableArray arrayWithCapacity:containers.count];
    BOOL foundCrossings = [self findCrossingsOnContainers:containers onRay:ray beforeMinimum:testMinimum afterMaximum:testMaximum crossingsBefore:crossingsBeforeMinimum crossingsAfter:crossingsAfterMaximum];
    if ( !foundCrossings )
        return NO;
    
    // Remove containers that appear an even number of times on either side, because by the even/odd rule
    //  they can't contain test contour.
    [self removeContoursThatDontContain:crossingsBeforeMinimum];
    [self removeContoursThatDontContain:crossingsAfterMaximum];
        
    // Remove containers that appear only on one side
    [self removeContourCrossings:crossingsBeforeMinimum thatDontAppearIn:crossingsAfterMaximum];
    [self removeContourCrossings:crossingsAfterMaximum thatDontAppearIn:crossingsBeforeMinimum];
    
    // Although crossingsBeforeMinimum and crossingsAfterMaximum contain different crossings, they should contain the same
    //  contours, so just pick one to pull the contours from
    [containers setArray:[self contoursFromCrossings:crossingsBeforeMinimum]];
    
    return YES;
}

- (NSArray *) contoursFromCrossings:(NSArray *)crossings
{
    // Determine all the unique contours in the array of crossings
    NSMutableArray *contours = [NSMutableArray arrayWithCapacity:crossings.count];
    for (FBEdgeCrossing *crossing in crossings) {
        if ( ![contours containsObject:crossing.edge.contour] )
            [contours addObject:crossing.edge.contour];
    }
    return contours;
}

- (void) removeContourCrossings:(NSMutableArray *)crossings1 thatDontAppearIn:(NSMutableArray *)crossings2
{
    // If a contour appears in crossings1, but not crossings2, remove all the associated crossings from 
    //  crossings1.
    
    NSMutableArray *containersToRemove = [NSMutableArray arrayWithCapacity:crossings1.count];
    for (FBEdgeCrossing *crossingToTest in crossings1) {
        FBBezierContour *containerToTest = crossingToTest.edge.contour;
        // See if this contour exists in the other array
        BOOL existsInOther = NO;
        for (FBEdgeCrossing *crossing in crossings2) {
            if ( crossing.edge.contour == containerToTest ) {
                existsInOther = YES;
                break;
            }
        }
        // If it doesn't exist in our counterpart, mark it for death
        if ( !existsInOther )
            [containersToRemove addObject:containerToTest];
    }
    [self removeCrossings:crossings1 forContours:containersToRemove];
}

- (void) removeContoursThatDontContain:(NSMutableArray *)crossings
{
    // Remove contours that cross the ray an even number of times. By the even/odd rule this means
    //  they can't contain the test contour.
    NSMutableArray *containersToRemove = [NSMutableArray arrayWithCapacity:crossings.count];
    for (FBEdgeCrossing *crossingToTest in crossings) {
        // For this contour, count how many times it appears in the crossings array
        FBBezierContour *containerToTest = crossingToTest.edge.contour;
        NSUInteger count = 0;
        for (FBEdgeCrossing *crossing in crossings) {
            if ( crossing.edge.contour == containerToTest )
                count++;
        }
        // If it's not an odd number of times, it doesn't contain the test contour, so mark it for death
        if ( (count % 2) != 1 )
            [containersToRemove addObject:containerToTest];
    }
    [self removeCrossings:crossings forContours:containersToRemove];
}

- (void) removeCrossings:(NSMutableArray *)crossings forContours:(NSArray *)containersToRemove
{
    // A helper method that goes through and removes all the crossings that appear on the specified
    //  contours.
    
    // First walk through and identify which crossings to remove
    NSMutableArray *crossingsToRemove = [NSMutableArray arrayWithCapacity:crossings.count];
    for (FBBezierContour *contour in containersToRemove) {
        for (FBEdgeCrossing *crossing in crossings) {
            if ( crossing.edge.contour == contour )
                [crossingsToRemove addObject:crossing];
        }
    }
    // Now walk through and remove the crossings
    for (FBEdgeCrossing *crossing in crossingsToRemove)
        [crossings removeObject:crossing];
}

- (void) markAllCrossingsAsUnprocessed
{
    for (FBBezierContour *contour in _contours)
        for (FBBezierCurve *edge in contour.edges) {
            [edge crossingsCopyWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
                crossing.processed = NO;
            }];
        }
}

- (FBEdgeCrossing *) firstUnprocessedCrossing
{
    // Find the first crossing in our graph that has yet to be processed by the bezierGraphFromIntersections
    //  method.
    
    for (FBBezierContour *contour in _contours) {
        for (FBBezierCurve *edge in contour.edges) {
            __block FBEdgeCrossing *unprocessedCrossing = nil;
            [edge crossingsWithBlock:^(FBEdgeCrossing *crossing, BOOL *stop) {
                if ( crossing.isSelfCrossing )
                    return;
                if ( !crossing.isProcessed ) {
                    unprocessedCrossing = crossing;
                    *stop = YES;
                }
            }];
            if ( unprocessedCrossing != nil )
                return unprocessedCrossing;
        }
    }
    return nil;
}

- (FBBezierGraph *) bezierGraphFromIntersections
{
    // This method walks the current graph, starting at the crossings, and outputs the final contours
    //  of the parts of the graph that actually intersect. The general algorithm is: start an crossing
    //  we haven't seen before. If it's marked as entry, start outputing edges moving forward (i.e. using edge.next)
    //  until another crossing is hit. (If a crossing is marked as exit, start outputting edges move backwards, using
    //  edge.previous.) Once the next crossing is hit, switch to the crossing's counter part in the other graph,
    //  and process it in the same way. Continue this until we reach a crossing that's been processed.
    
    FBBezierGraph *result = [FBBezierGraph bezierGraph];
    
    // Find the first crossing to start one
    FBEdgeCrossing *crossing = [self firstUnprocessedCrossing];
    while ( crossing != nil ) {
        // This is the start of a contour, so create one
        FBBezierContour *contour = [[FBBezierContour alloc] init];
        [result addContour:contour];
        
        // Keep going until we run into a crossing we've seen before.
        while ( !crossing.isProcessed ) {
            crossing.processed = YES; // ...and we've just seen this one
            
            if ( crossing.isEntry ) {
                // Keep going to next until meet a crossing
                [contour addCurveFrom:crossing to:crossing.nextNonself];
                if ( crossing.nextNonself == nil ) {
                    // We hit the end of the edge without finding another crossing, so go find the next crossing
                    FBBezierCurve *edge = crossing.edge.next;
                    while ( !edge.hasNonselfCrossings ) {
                        // output this edge whole
                        [contour addCurve:[edge clone]]; // make a copy to add. contours don't share too good
                        
                        edge = edge.next;
                    }
                    // We have an edge that has at least one crossing
                    crossing = edge.firstNonselfCrossing;
                    [contour addCurveFrom:nil to:crossing]; // add the curve up to the crossing
                } else
                    crossing = crossing.nextNonself; // this edge has a crossing, so just move to it
            } else {
                // Keep going to previous until meet a crossing
                [contour addReverseCurveFrom:crossing.previousNonself to:crossing];
                if ( crossing.previousNonself == nil ) {
                    // we hit the end of the edge without finding another crossing, so go find the previous crossing
                    FBBezierCurve *edge = crossing.edge.previous;
                    while ( !edge.hasNonselfCrossings ) {
                        // output this edge whole
                        [contour addReverseCurve:edge];
                        
                        edge = edge.previous;
                    }
                    // We have an edge that has at least one edge
                    crossing = edge.lastNonselfCrossing;
                    [contour addReverseCurveFrom:crossing to:nil]; // add the curve up to the crossing
                } else
                    crossing = crossing.previousNonself;
            }
            
            // Switch over to counterpart in the other graph
            crossing.processed = YES;
            crossing = crossing.counterpart;
        }
        
        // See if there's another contour that we need to handle
        crossing = [self firstUnprocessedCrossing];
    }
    
    return result;
}

- (void) removeCrossings
{
    // Crossings only make sense for the intersection between two specific graphs. In order for this
    //  graph to be usable in the future, remove all the crossings
    for (FBBezierContour *contour in _contours)
        for (FBBezierCurve *edge in contour.edges)
            [edge removeAllCrossings];
}

- (void) removeOverlaps
{
    for (FBBezierContour *contour in _contours)
        [contour removeAllOverlaps];
}

- (void) addContour:(FBBezierContour *)contour
{
    // Add a contour to ouselves, and force the bounds to be recalculated
    [_contours addObject:contour];
    _bounds = NSZeroRect;
}

- (NSArray *) nonintersectingContours
{
    // Find all the contours that have no crossings on them.
    NSMutableArray *contours = [NSMutableArray arrayWithCapacity:_contours.count];
    for (FBBezierContour *contour in self.contours) {
        if ( (contour.intersectingContours).count == 0 )
            [contours addObject:contour];
    }
    return contours;
}

- (void) debuggingInsertCrossingsForUnionWithBezierGraph:(FBBezierGraph *)otherGraph
{
    [self debuggingInsertCrossingsWithBezierGraph:otherGraph markInside:NO markOtherInside:NO];
}

- (void) debuggingInsertCrossingsForIntersectWithBezierGraph:(FBBezierGraph *)otherGraph
{
    [self debuggingInsertCrossingsWithBezierGraph:otherGraph markInside:YES markOtherInside:YES];
}

- (void) debuggingInsertCrossingsForDifferenceWithBezierGraph:(FBBezierGraph *)otherGraph
{
    [self debuggingInsertCrossingsWithBezierGraph:otherGraph markInside:NO markOtherInside:YES];
}

- (void) debuggingInsertCrossingsWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside markOtherInside:(BOOL)markOtherInside
{
    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    [self removeCrossings];
    [otherGraph removeCrossings];
    [self removeOverlaps];
    [otherGraph removeOverlaps];

    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    [self insertCrossingsWithBezierGraph:otherGraph];
    [self insertSelfCrossings];
    [otherGraph insertSelfCrossings];
    
    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    [self markCrossingsAsEntryOrExitWithBezierGraph:otherGraph markInside:markInside];
    [otherGraph markCrossingsAsEntryOrExitWithBezierGraph:self markInside:markOtherInside];    
}

- (void) debuggingInsertIntersectionsWithBezierGraph:(FBBezierGraph *)otherGraph
{
    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    [self removeCrossings];
    [otherGraph removeCrossings];
    [self removeOverlaps];
    [otherGraph removeOverlaps];

    for (FBBezierContour *ourContour in self.contours) {
        for (FBBezierCurve *ourEdge in ourContour.edges) {
            for (FBBezierContour *theirContour in otherGraph.contours) {
                for (FBBezierCurve *theirEdge in theirContour.edges) {
                    // Find all intersections between these two edges (curves)
                    FBBezierIntersectRange *intersectRange = nil;
                    [ourEdge intersectionsWithBezierCurve:theirEdge overlapRange:&intersectRange withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                        FBEdgeCrossing *ourCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        FBEdgeCrossing *theirCrossing = [FBEdgeCrossing crossingWithIntersection:intersection];
                        ourCrossing.counterpart = theirCrossing;
                        theirCrossing.counterpart = ourCrossing;
                        [ourEdge addCrossing:ourCrossing];
                        [theirEdge addCrossing:theirCrossing];
                    }];
                }                
            }
        }
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: bounds = (%f, %f)(%f, %f) contours = %@>", 
            NSStringFromClass([self class]), 
            NSMinX(self.bounds), NSMinY(self.bounds),
            NSWidth(self.bounds), NSHeight(self.bounds),
            FBArrayDescription(_contours)];
}

@end
